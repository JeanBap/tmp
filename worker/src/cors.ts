import type { Env } from './env';

export function corsHeaders(req: Request, env: Env): Record<string, string> {
  const origin = req.headers.get('Origin') ?? '';
  // Reflect only when the origin matches the allowed one — never use '*'.
  const allow = origin === env.ALLOWED_ORIGIN ? origin : '';
  return {
    'Access-Control-Allow-Origin': allow,
    'Vary': 'Origin',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    'Access-Control-Max-Age': '86400',
  };
}

export function corsPreflight(req: Request, env: Env): Response {
  return new Response(null, { status: 204, headers: corsHeaders(req, env) });
}

export function withCors(req: Request, env: Env, res: Response): Response {
  const headers = new Headers(res.headers);
  for (const [k, v] of Object.entries(corsHeaders(req, env))) headers.set(k, v);
  return new Response(res.body, { status: res.status, headers });
}

export function jsonResponse(req: Request, env: Env, body: unknown, init: ResponseInit = {}): Response {
  return withCors(
    req,
    env,
    new Response(JSON.stringify(body), {
      ...init,
      headers: { 'Content-Type': 'application/json; charset=utf-8', ...init.headers },
    }),
  );
}
