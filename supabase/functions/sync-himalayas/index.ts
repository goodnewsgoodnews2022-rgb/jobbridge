// Supabase Edge Function: sync-himalayas
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

Deno.serve(async (_req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
    const res = await fetch('https://himalayas.app/jobs/api?limit=100', {
      headers: { 'Accept': 'application/json' },
    });
    const data = await res.json();
    const jobs = data.jobs ?? [];
    let inserted = 0, updated = 0;

    for (const j of jobs) {
      const row = {
        source: 'himalayas',
        external_id: String(j.id ?? j.slug),
        title: j.title,
        description: j.description ?? '',
        requirements: (j.requirements ?? []).join('\n'),
        company_name: j.companyName ?? j.company_name ?? '',
        company_logo: j.companyLogo ?? j.company_logo ?? null,
        location: j.locationRestrictions?.join(', ') ?? 'Worldwide',
        country: '',
        remote_type: 'Remote',
        employment_type: j.employmentType ?? 'Full-time',
        category: (j.categories ?? [])[0] ?? '',
        salary_min: j.minSalary ?? null,
        salary_max: j.maxSalary ?? null,
        salary_currency: 'USD',
        skills: j.skills ?? [],
        job_url: j.applicationLink ?? j.url ?? '',
        apply_url: j.applicationLink ?? j.url ?? '',
        posted_at: j.pubDate
          ? new Date(j.pubDate * 1000).toISOString()
          : new Date().toISOString(),
        expires_at: j.expiryDate
          ? new Date(j.expiryDate * 1000).toISOString()
          : null,
        status: 'active',
      };

      const { data: existing } = await supabase
        .from('jobs')
        .select('id')
        .eq('source', 'himalayas')
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

    // Expire old jobs
    await supabase
      .from('jobs')
      .update({ status: 'expired' })
      .lt('expires_at', new Date().toISOString())
      .eq('status', 'active');

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