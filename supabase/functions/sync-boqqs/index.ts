// Supabase Edge Function: sync-boqqs
// Fetches jobs from BOQQS and upserts them into the jobs table.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

Deno.serve(async (req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
    const url = new URL(req.url);
    const pages = Number(url.searchParams.get('pages') ?? '3');
    let inserted = 0, updated = 0;

    for (let page = 1; page <= pages; page++) {
      const res = await fetch(
        `https://boqqs.com/api/v1/jobs?page=${page}&per_page=50`,
        { headers: { 'Accept': 'application/json' } },
      );
      if (!res.ok) break;
      const data = await res.json();
      const jobs = data.jobs ?? data.data ?? data ?? [];
      if (!Array.isArray(jobs) || jobs.length === 0) break;

      for (const j of jobs) {
        const row = {
          source: 'boqqs',
          external_id: String(j.id),
          title: j.title,
          description: j.description ?? '',
          requirements: j.requirements ?? '',
          company_name: j.company?.name ?? j.company_name ?? 'Unknown',
          company_logo: j.company?.logo ?? null,
          location: j.location ?? '',
          country: j.country ?? '',
          remote_type: j.remote_type ?? (j.remote ? 'Remote' : 'Onsite'),
          employment_type: j.employment_type ?? 'Full-time',
          category: j.category ?? '',
          salary_min: j.salary_min ?? null,
          salary_max: j.salary_max ?? null,
          salary_currency: j.salary_currency ?? 'GBP',
          skills: j.skills ?? [],
          job_url: j.url ?? `https://boqqs.com/jobs/${j.id}`,
          apply_url: j.apply_url ?? j.url ?? `https://boqqs.com/jobs/${j.id}`,
          posted_at: j.posted_at ?? new Date().toISOString(),
          expires_at: j.expires_at ?? null,
          status: 'active',
        };

        const { data: existing } = await supabase
          .from('jobs')
          .select('id')
          .eq('source', 'boqqs')
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