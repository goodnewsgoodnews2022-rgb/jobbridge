// Supabase Edge Function: paystack-init
// Creates a Paystack transaction for EITHER:
//   1. Company packages (job postings, bundles, subscriptions, ads, verification)
//   2. Resume packages (job seeker CV upgrades)
// Returns the checkout URL.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL    = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY     = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const PAYSTACK_SECRET = Deno.env.get('PAYSTACK_SECRET_KEY')!;

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-supabase-api-version',
  'Access-Control-Max-Age': '86400',
};

// ═══════════════════════════════════════════════════════════════════
// PACKAGE PRICES
// ═══════════════════════════════════════════════════════════════════

type PackageKind = 'company' | 'resume';

interface PackageInfo {
  amount: number;
  label: string;
  kind: PackageKind;
}

const PRICES: Record<string, PackageInfo> = {
  // ── Company / Job packages ──
  'job-basic':       { amount: 3000,  label: 'Basic Job Post',              kind: 'company' },
  'job-featured':    { amount: 7000,  label: 'Featured Job Post',           kind: 'company' },
  'job-premium':     { amount: 15000, label: 'Premium Job Post',            kind: 'company' },
  'bundle-5':        { amount: 12000, label: '5 Job Bundle',                kind: 'company' },
  'bundle-10':       { amount: 20000, label: '10 Job Bundle',               kind: 'company' },
  'bundle-25':       { amount: 45000, label: '25 Job Bundle',               kind: 'company' },
  'sub-starter':     { amount: 10000, label: 'Starter Subscription',        kind: 'company' },
  'sub-business':    { amount: 25000, label: 'Business Subscription',       kind: 'company' },
  'verify-employer': { amount: 10000, label: 'Verified Employer Badge',     kind: 'company' },
  'ad-homepage':     { amount: 50000, label: 'Homepage Ad Banner',          kind: 'company' },
  'ad-jobs':         { amount: 25000, label: 'Jobs Page Ad',                kind: 'company' },

  // ── Resume / CV packages ──
  'resume-pro':      { amount: 2500,  label: 'Professional CV',             kind: 'resume'  },
  'resume-career':   { amount: 5000,  label: 'Career Pack (CV + Cover)',    kind: 'resume'  },
};

// ═══════════════════════════════════════════════════════════════════
// MAIN HANDLER
// ═══════════════════════════════════════════════════════════════════

Deno.serve(async (req) => {
  // ── CORS preflight ──
  if (req.method === 'OPTIONS') {
    return new Response('ok', { status: 200, headers: CORS_HEADERS });
  }

  try {
    const body = await req.json();
    const {
      package_id,
      company_id,
      job_id,
      resume_id,
      callback_url,
    } = body;

    // ── 1. Validate package ──
    if (!package_id) {
      return json({ ok: false, error: 'Missing package_id' }, 400);
    }

    const pkg = PRICES[package_id];
    if (!pkg) {
      return json({ ok: false, error: `Unknown package: ${package_id}` }, 400);
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

    // ═══════════════════════════════════════════════════════════
    // RESUME ORDER FLOW
    // ═══════════════════════════════════════════════════════════
    if (pkg.kind === 'resume') {
      return await handleResumeOrder(
        supabase,
        { package_id, resume_id, callback_url },
        pkg,
      );
    }

    // ═══════════════════════════════════════════════════════════
    // COMPANY ORDER FLOW
    // ═══════════════════════════════════════════════════════════
    return await handleCompanyOrder(
      supabase,
      { package_id, company_id, job_id, callback_url },
      pkg,
    );
  } catch (e) {
    return json({ ok: false, error: String(e) }, 500);
  }
});

// ═══════════════════════════════════════════════════════════════════
// COMPANY ORDER (jobs, bundles, subs, ads, verification)
// ═══════════════════════════════════════════════════════════════════

async function handleCompanyOrder(
  supabase: any,
  p: {
    package_id: string;
    company_id?: string;
    job_id?: string;
    callback_url?: string;
  },
  pkg: PackageInfo,
) {
  if (!p.company_id) {
    return json({ ok: false, error: 'Missing company_id' }, 400);
  }

  // Look up company for email
  const { data: company } = await supabase
    .from('companies')
    .select('name, email, owner_id')
    .eq('id', p.company_id)
    .maybeSingle();

  if (!company) {
    return json({ ok: false, error: 'Company not found' }, 404);
  }

  const reference = makeReference();

  // Insert into job_orders
  const { data: order, error: orderErr } = await supabase
    .from('job_orders')
    .insert({
      company_id: p.company_id,
      job_id: p.job_id ?? null,
      package: p.package_id,
      amount: pkg.amount,
      currency: 'NGN',
      payment_status: 'pending',
      payment_reference: reference,
      payment_provider: 'paystack',
    })
    .select()
    .single();

  if (orderErr || !order) {
    return json(
      { ok: false, error: 'Could not create order: ' + (orderErr?.message ?? '') },
      500,
    );
  }

  // Build metadata with all necessary context
  const metadata = {
    order_id: order.id,
    company_id: p.company_id,
    job_id: p.job_id ?? null,
    package_id: p.package_id,
    order_type: 'company',
    custom_fields: [
      { display_name: 'Company', variable_name: 'company', value: company.name },
      { display_name: 'Package', variable_name: 'package', value: pkg.label },
    ],
  };

  return await initializePaystack({
    email: company.email || 'noreply@jobbridge.ng',
    reference,
    amount: pkg.amount,
    callback_url: p.callback_url,
    metadata,
    orderId: order.id,
    packageId: p.package_id,
    amountNum: pkg.amount,
  });
}

// ═══════════════════════════════════════════════════════════════════
// RESUME ORDER (job seeker CV upgrades)
// ═══════════════════════════════════════════════════════════════════

async function handleResumeOrder(
  supabase: any,
  p: {
    package_id: string;
    resume_id?: string;
    callback_url?: string;
  },
  pkg: PackageInfo,
) {
  if (!p.resume_id) {
    return json({ ok: false, error: 'Missing resume_id' }, 400);
  }

  // Look up the resume and its owner
  const { data: resume } = await supabase
    .from('resumes')
    .select('id, user_id, title, full_name, email')
    .eq('id', p.resume_id)
    .maybeSingle();

  if (!resume) {
    return json({ ok: false, error: 'Resume not found' }, 404);
  }

  // Get user email from auth.users (more reliable than resume.email)
  const { data: userData } = await supabase.auth.admin.getUserById(resume.user_id);
  const userEmail =
    userData?.user?.email ||
    resume.email ||
    'noreply@jobbridge.ng';

  const reference = makeReference();

  // Insert into resume_orders
  const { data: order, error: orderErr } = await supabase
    .from('resume_orders')
    .insert({
      user_id: resume.user_id,
      resume_id: p.resume_id,
      package: p.package_id,
      amount: pkg.amount,
      currency: 'NGN',
      payment_status: 'pending',
      payment_reference: reference,
      payment_provider: 'paystack',
    })
    .select()
    .single();

  if (orderErr || !order) {
    return json(
      { ok: false, error: 'Could not create resume order: ' + (orderErr?.message ?? '') },
      500,
    );
  }

  // Build metadata with all necessary context
  const metadata = {
    order_id: order.id,
    user_id: resume.user_id,
    resume_id: p.resume_id,
    package_id: p.package_id,
    order_type: 'resume',
    custom_fields: [
      { display_name: 'Resume', variable_name: 'resume', value: resume.title || 'My Resume' },
      { display_name: 'Package', variable_name: 'package', value: pkg.label },
    ],
  };

  return await initializePaystack({
    email: userEmail,
    reference,
    amount: pkg.amount,
    callback_url: p.callback_url,
    metadata,
    orderId: order.id,
    packageId: p.package_id,
    amountNum: pkg.amount,
  });
}

// ═══════════════════════════════════════════════════════════════════
// SHARED: Call Paystack + return checkout URL
// ═══════════════════════════════════════════════════════════════════

async function initializePaystack(p: {
  email: string;
  reference: string;
  amount: number;
  callback_url?: string;
  metadata: Record<string, unknown>;
  orderId: string;
  packageId: string;
  amountNum: number;
}) {
  const res = await fetch('https://api.paystack.co/transaction/initialize', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${PAYSTACK_SECRET}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email: p.email,
      amount: p.amount * 100,         // Paystack uses kobo
      currency: 'NGN',
      reference: p.reference,
      callback_url:
        p.callback_url || 'https://jobbridge.ng/#/payment/success',
      metadata: p.metadata,
    }),
  });

  const data = await res.json();

  if (!data.status) {
    return json(
      { ok: false, error: data.message || 'Paystack error' },
      500,
    );
  }

  return json({
    ok: true,
    order_id: p.orderId,
    reference: p.reference,
    checkout_url: data.data.authorization_url,
    access_code: data.data.access_code,
    amount: p.amountNum,
  });
}

// ═══════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════

function makeReference(): string {
  return `JB-${Date.now()}-${Math.floor(Math.random() * 100000)}`;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
    },
  });
}