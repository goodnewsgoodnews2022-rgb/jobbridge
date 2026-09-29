// Supabase Edge Function: sync-progigfinder
// Fetches African jobs from ProGigFinder and upserts them into the jobs table.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

Deno.serve(async (_req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

    // ProGigFinder API endpoint (no auth required)
    const res = await fetch('https://www.progigfinder.com/api/feed/jobs?format=json', {
      headers: { 'Accept': 'application/json' },
    });

    if (!res.ok) {
      return new Response(JSON.stringify({ ok: false, error: 'ProGigFinder API error' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const data = await res.json();
    const jobs = data.jobs ?? [];
    let inserted = 0;
    let updated = 0;

    for (const j of jobs) {
      // Normalize the ProGigFinder job object to your jobs table schema
      const row = {
        source: 'progigfinder',
        external_id: String(j.id),
        title: j.title ?? '',
        description: j.description ?? '',
        requirements: j.requirements ?? j.responsibilities ?? '',
        company_name: j.company ?? 'Unknown',
        company_logo: null, // ProGigFinder feed doesn't provide logos
        location: j.location ?? '',
        country: j.country ?? '',
        remote_type: j.is_remote ? 'Remote' : 'Onsite',
        employment_type: j.job_type === 'full_time' ? 'Full-time' : 'Contract',
        category: j.category ?? '',
        salary_min: j.salary?.min ?? null,
        salary_max: j.salary?.max ?? null,
        salary_currency: j.salary?.currency ?? 'USD',
        skills: [],
        job_url: j.url ?? '',
        apply_url: j.apply_url ?? j.url ?? '',
        posted_at: j.posted_date ?? new Date().toISOString(),
        expires_at: j.expiry_date ?? null,
        status: 'active',
      };

      const { data: existing } = await supabase
        .from('jobs')
        .select('id')
        .eq('source', 'progigfinder')
        .eq('external_id', row.external_id)
        .maybeSingle();

      if (existing) {
        await supabase.from('jobs').update(row).eq('id', existing.id);
        updated++;
      } else {
        await supabase.from('jobs').insert(row);
        inserted++;
      }
    }

    return new Response(JSON.stringify({ ok: true, inserted, updated }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});