// Supabase Edge Function: image-proxy
// Proxies external images (Himalayas, etc.) that lack CORS headers,
// so Flutter Web can render them without CORS blocking.

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      },
    });
  }

  try {
    const url = new URL(req.url);
    const target = url.searchParams.get('url');
    if (!target) {
      return new Response('Missing url parameter', { status: 400 });
    }

    // Whitelist allowed domains for security
    const allowed = [
      'himalayas.app',
      'cdn-images.himalayas.app',
      'arbeitnow.com',
      'boqqs.com',
      'lever.co',
      'greenhouse.io',
      'workable.com',
      'ashbyhq.com',
      'logo.clearbit.com',
    ];
    const host = new URL(target).hostname;
    if (!allowed.some((d) => host === d || host.endsWith('.' + d))) {
      return new Response('Domain not allowed', { status: 403 });
    }

    const upstream = await fetch(target, {
      headers: { 'User-Agent': 'JobBridge/1.0' },
    });

    if (!upstream.ok) {
      return new Response('Upstream error', { status: upstream.status });
    }

    const contentType = upstream.headers.get('content-type') ?? 'image/png';
    const body = await upstream.arrayBuffer();

    return new Response(body, {
      headers: {
        'Content-Type': contentType,
        'Cache-Control': 'public, max-age=86400, immutable',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
      },
    });
  } catch (e) {
    return new Response(`Proxy error: ${e}`, { status: 500 });
  }
});