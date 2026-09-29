// Supabase Edge Function: sync-arbeitnow
// Fetches jobs from Arbeitnow and upserts them into the jobs table.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

/**
 * Robustly parse a date value into an ISO 8601 string.
 * Handles:
 *   - Unix seconds (number, e.g. 1727000000)
 *   - Unix milliseconds (number, e.g. 1727000000000)
 *   - Numeric strings ("1727000000")
 *   - ISO strings ("2026-09-22T10:00:00Z")
 *   - Missing / invalid values → falls back to current time
 */
function parseArbeitnowDate(value: unknown): string {
  // 1. Missing value → now
  if (value === null || value === undefined || value === '') {
    return new Date().toISOString();
  }

  // 2. Numeric (seconds or milliseconds)
  if (typeof value === 'number' && Number.isFinite(value)) {
    // Heuristic: 10 billion ms ≈ year 2286. Anything smaller is likely seconds.
    const ms = value < 10_000_000_000 ? value * 1000 : value;
    return new Date(ms).toISOString();
  }

  // 3. Numeric string
  if (typeof value === 'string' && /^\d+$/.test(value.trim())) {
    const num = parseInt(value.trim(), 10);
    const ms = num < 10_000_000_000 ? num * 1000 : num;
    return new Date(ms).toISOString();
  }

  // 4. Date-parseable string (ISO, RFC 2822, etc.)
  if (typeof value === 'string') {
    const parsed = new Date(value);
    if (!isNaN(parsed.getTime())) {
      return parsed.toISOString();
    }
  }

  // 5. Everything else → now
  return new Date().toISOString();
}

/**
 * Best-effort country detection from a location string.
 * Arbeitnow is predominantly European.
 */
function detectCountry(location: string | undefined | null): string {
  if (!location) return 'EU';
  const loc = location.toLowerCase();

  const map: Record<string, string> = {
    // UK
    'united kingdom': 'UK', 'england': 'UK', 'london': 'UK',
    'manchester': 'UK', 'birmingham': 'UK', 'edinburgh': 'UK',
    'glasgow': 'UK', 'leeds': 'UK', 'bristol': 'UK', 'uk': 'UK',

    // Germany
    'germany': 'Germany', 'berlin': 'Germany', 'munich': 'Germany',
    'münchen': 'Germany', 'hamburg': 'Germany', 'frankfurt': 'Germany',
    'cologne': 'Germany', 'köln': 'Germany', 'stuttgart': 'Germany',
    'düsseldorf': 'Germany', 'dusseldorf': 'Germany', 'leipzig': 'Germany',
    'dresden': 'Germany', 'deutschland': 'Germany',

    // France
    'france': 'France', 'paris': 'France', 'lyon': 'France',
    'marseille': 'France', 'toulouse': 'France', 'bordeaux': 'France',

    // Netherlands
    'netherlands': 'Netherlands', 'amsterdam': 'Netherlands',
    'rotterdam': 'Netherlands', 'utrecht': 'Netherlands',

    // Spain
    'spain': 'Spain', 'madrid': 'Spain', 'barcelona': 'Spain',
    'valencia': 'Spain',

    // Italy
    'italy': 'Italy', 'rome': 'Italy', 'roma': 'Italy',
    'milan': 'Italy', 'milano': 'Italy',

    // Switzerland
    'switzerland': 'Switzerland', 'zurich': 'Switzerland',
    'zürich': 'Switzerland', 'geneva': 'Switzerland', 'basel': 'Switzerland',

    // Austria
    'austria': 'Austria', 'vienna': 'Austria', 'wien': 'Austria',

    // Nordics
    'sweden': 'Sweden', 'stockholm': 'Sweden',
    'norway': 'Norway', 'oslo': 'Norway',
    'denmark': 'Denmark', 'copenhagen': 'Denmark',
    'finland': 'Finland', 'helsinki': 'Finland',

    // Africa (rare on Arbeitnow but possible)
    'nigeria': 'Nigeria', 'lagos': 'Nigeria', 'abuja': 'Nigeria',
    'kenya': 'Kenya', 'nairobi': 'Kenya',
    'south africa': 'South Africa', 'johannesburg': 'South Africa',
    'cape town': 'South Africa',
  };

  for (const [key, country] of Object.entries(map)) {
    if (loc.includes(key)) return country;
  }
  return 'EU';
}

Deno.serve(async (_req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

    // Fetch from Arbeitnow API
    const res = await fetch('https://www.arbeitnow.com/api/job-board-api', {
      headers: { 'Accept': 'application/json' },
    });

    if (!res.ok) {
      return new Response(
        JSON.stringify({ ok: false, error: `Arbeitnow API status ${res.status}` }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      );
    }

    const data = await res.json();
    const jobs = data.data ?? [];
    let inserted = 0;
    let updated = 0;
    let skipped = 0;

    for (const j of jobs) {
      // Skip malformed entries
      if (!j.slug || !j.title) {
        skipped++;
        continue;
      }

      const postedIso = parseArbeitnowDate(j.created_at);

      // Compute expiry = posted + 30 days
      const expiresIso = new Date(
        new Date(postedIso).getTime() + 30 * 24 * 60 * 60 * 1000,
      ).toISOString();

      const row = {
        source: 'arbeitnow',
        external_id: String(j.slug),
        title: j.title,
        description: j.description ?? '',
        requirements: '',
        company_name: j.company_name ?? '',
        company_logo: j.company_logo ?? null,
        location: j.location ?? '',
        country: detectCountry(j.location),
        remote_type: j.remote ? 'Remote' : 'Onsite',
        employment_type: 'Full-time',
        category: j.category ?? '',
        salary_min: null,
        salary_max: null,
        salary_currency: 'EUR',
        skills: Array.isArray(j.tags) ? j.tags.map((t: string) => t.trim()) : [],
        job_url: j.url ?? '',
        apply_url: j.url ?? '',
        posted_at: postedIso,      // ✅ Robust parsing — no more NaN crashes
        expires_at: expiresIso,    // ✅ Auto-expire after 30 days
        status: 'active',
      };

      // Upsert by (source, external_id)
      const { data: existing } = await supabase
        .from('jobs')
        .select('id')
        .eq('source', 'arbeitnow')
        .eq('external_id', row.external_id)
        .maybeSingle();

      if (existing) {
        // Don't overwrite posted_at on update — preserve original post date
        const { posted_at: _ignored, ...updateRow } = row;
        await supabase.from('jobs').update(updateRow).eq('id', existing.id);
        updated++;
      } else {
        await supabase.from('jobs').insert(row);
        inserted++;
      }
    }

    // Expire old Arbeitnow jobs (older than 30 days, still marked active)
    await supabase
      .from('jobs')
      .update({ status: 'expired' })
      .eq('source', 'arbeitnow')
      .eq('status', 'active')
      .lt('expires_at', new Date().toISOString());

    return new Response(
      JSON.stringify({ ok: true, inserted, updated, skipped }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ ok: false, error: String(e) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});