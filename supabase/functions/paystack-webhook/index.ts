// Supabase Edge Function: paystack-webhook
// Receives Paystack payment confirmations and fulfills orders.
//
// Handles TWO order types:
//   1. Company orders (job posts, bundles, subscriptions, ads, verification)
//   2. Resume orders (job seeker CV upgrades)
//
// Which type is determined by metadata.order_type set by paystack-init.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL    = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY     = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const PAYSTACK_SECRET = Deno.env.get('PAYSTACK_SECRET_KEY')!;

Deno.serve(async (req) => {
  try {
    // ═══════════════════════════════════════════════════════════
    // 1. VERIFY PAYSTACK SIGNATURE
    // ═══════════════════════════════════════════════════════════
    const body = await req.text();

    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(PAYSTACK_SECRET),
      { name: 'HMAC', hash: 'SHA-512' },
      false,
      ['sign'],
    );
    const sigBuffer = await crypto.subtle.sign('HMAC', key, encoder.encode(body));
    const signature = Array.from(new Uint8Array(sigBuffer))
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');

    const paystackSignature = req.headers.get('x-paystack-signature');
    if (signature !== paystackSignature) {
      console.error('❌ Invalid Paystack signature');
      return new Response('Invalid signature', { status: 401 });
    }

    // ═══════════════════════════════════════════════════════════
    // 2. PARSE EVENT
    // ═══════════════════════════════════════════════════════════
    const event = JSON.parse(body);
    if (event.event !== 'charge.success') {
      return new Response('Ignored', { status: 200 });
    }

    const { reference, metadata, amount: amountKobo } = event.data;
    const orderId    = metadata?.order_id;
    const companyId  = metadata?.company_id;
    const jobId      = metadata?.job_id;
    const resumeId   = metadata?.resume_id;
    const userId     = metadata?.user_id;
    const packageId  = metadata?.package_id;
    // Default to company for old orders that don't have order_type
    const orderType  = metadata?.order_type ?? 'company';
    const amountNaira = typeof amountKobo === 'number' ? amountKobo / 100 : null;

    console.log(`💳 Payment received: ref=${reference}, type=${orderType}, pkg=${packageId}`);

    if (!orderId) {
      console.warn('⚠️ No order_id in metadata');
      return new Response('No order', { status: 200 });
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

    // ═══════════════════════════════════════════════════════════
    // 3. RESUME ORDERS
    // ═══════════════════════════════════════════════════════════
    if (orderType === 'resume' || packageId?.startsWith('resume-')) {
      return await fulfillResumeOrder(supabase, {
        orderId,
        resumeId,
        userId,
        packageId,
        reference,
        amountNaira,
        rawEvent: event.data,
      });
    }

    // ═══════════════════════════════════════════════════════════
    // 4. COMPANY ORDERS
    // ═══════════════════════════════════════════════════════════
    return await fulfillCompanyOrder(supabase, {
      orderId,
      companyId,
      jobId,
      packageId,
      reference,
      amountNaira,
      rawEvent: event.data,
    });
  } catch (e) {
    console.error('❌ Webhook error:', e);
    return new Response(`Error: ${e}`, { status: 500 });
  }
});

// ═══════════════════════════════════════════════════════════════════
// COMPANY ORDER FULFILLMENT
// ═══════════════════════════════════════════════════════════════════

async function fulfillCompanyOrder(
  supabase: any,
  p: {
    orderId: string;
    companyId?: string;
    jobId?: string;
    packageId?: string;
    reference: string;
    amountNaira: number | null;
    rawEvent: any;
  },
): Promise<Response> {
  // ─── Mark job_order paid ───
  await supabase
    .from('job_orders')
    .update({
      payment_status: 'paid',
      paid_at: new Date().toISOString(),
      payment_metadata: p.rawEvent,
    })
    .eq('id', p.orderId);

  console.log(`✅ Job order ${p.orderId} marked paid`);

  // ─── Package-specific fulfillment ───

  // Basic job post
  if (p.packageId === 'job-basic' && p.jobId) {
    await supabase.from('jobs').update({
      package: 'basic',
      payment_status: 'paid',
      status: 'active',
    }).eq('id', p.jobId);
    console.log(`✅ Job ${p.jobId} activated (basic)`);
  }

  // Featured job post
  if (p.packageId === 'job-featured' && p.jobId) {
    await supabase.from('jobs').update({
      package: 'featured',
      payment_status: 'paid',
      status: 'active',
      featured: true,
      featured_until: new Date(
        Date.now() + 30 * 24 * 60 * 60 * 1000,
      ).toISOString(),
    }).eq('id', p.jobId);
    console.log(`✅ Job ${p.jobId} activated + featured 30d`);
  }

  // Premium job post
  if (p.packageId === 'job-premium' && p.jobId) {
    await supabase.from('jobs').update({
      package: 'premium',
      payment_status: 'paid',
      status: 'active',
      featured: true,
      featured_until: new Date(
        Date.now() + 60 * 24 * 60 * 60 * 1000,
      ).toISOString(),
    }).eq('id', p.jobId);
    console.log(`✅ Job ${p.jobId} activated + premium 60d`);
  }

  // Job bundles
  if (p.packageId?.startsWith('bundle-')) {
    const credits =
      p.packageId === 'bundle-5' ? 5 :
      p.packageId === 'bundle-10' ? 10 :
      25;
    await supabase.from('bundles').insert({
      company_id: p.companyId,
      package_name: p.packageId,
      credits_total: credits,
      amount: p.amountNaira,
      payment_status: 'paid',
      payment_reference: p.reference,
      expires_at: new Date(
        Date.now() + 365 * 24 * 60 * 60 * 1000,
      ).toISOString(),
    });
    console.log(`✅ Bundle purchased: ${credits} credits`);
  }

  // Subscriptions
  if (p.packageId === 'sub-starter' || p.packageId === 'sub-business') {
    const amount = p.packageId === 'sub-starter' ? 10000 : 25000;
    await supabase.from('subscriptions').insert({
      company_id: p.companyId,
      plan: p.packageId === 'sub-starter' ? 'starter' : 'business',
      amount: p.amountNaira ?? amount,
      currency: 'NGN',
      status: 'active',
      current_period_start: new Date().toISOString(),
      current_period_end: new Date(
        Date.now() + 30 * 24 * 60 * 60 * 1000,
      ).toISOString(),
      payment_provider: 'paystack',
      payment_reference: p.reference,
    });
    console.log(`✅ Subscription activated: ${p.packageId}`);
  }

  // Verified employer badge
  if (p.packageId === 'verify-employer') {
    await supabase.from('companies').update({
      verified: true,
      verified_at: new Date().toISOString(),
    }).eq('id', p.companyId);

    await supabase.from('verification_orders').insert({
      company_id: p.companyId,
      amount: p.amountNaira,
      payment_status: 'paid',
      payment_reference: p.reference,
      verified_at: new Date().toISOString(),
    });
    console.log(`✅ Company ${p.companyId} verified`);
  }

  // Ad packages
  if (p.packageId?.startsWith('ad-')) {
    await supabase.from('employer_ads').update({
      status: 'active',
      payment_reference: p.reference,
    }).eq('payment_reference', p.reference);
    console.log(`✅ Ad activated: ${p.packageId}`);
  }

  return new Response('OK', { status: 200 });
}

// ═══════════════════════════════════════════════════════════════════
// RESUME ORDER FULFILLMENT
// ═══════════════════════════════════════════════════════════════════

async function fulfillResumeOrder(
  supabase: any,
  p: {
    orderId: string;
    resumeId?: string;
    userId?: string;
    packageId?: string;
    reference: string;
    amountNaira: number | null;
    rawEvent: any;
  },
): Promise<Response> {
  // ─── Mark resume_order paid ───
  await supabase
    .from('resume_orders')
    .update({
      payment_status: 'paid',
      paid_at: new Date().toISOString(),
    })
    .eq('id', p.orderId);

  console.log(`✅ Resume order ${p.orderId} marked paid`);

  // ─── Upgrade the resume ───
  if (p.resumeId) {
    await supabase.from('resumes').update({
      is_pro: true,
      package: p.packageId,
      payment_status: 'paid',
      updated_at: new Date().toISOString(),
    }).eq('id', p.resumeId);
    console.log(`✅ Resume ${p.resumeId} upgraded to Pro (${p.packageId})`);
  }

  return new Response('OK', { status: 200 });
}