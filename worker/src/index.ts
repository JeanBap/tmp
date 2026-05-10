import type { Env } from './env';
import { corsPreflight, jsonResponse } from './cors';
import { AuthError, verifyGoogleIdToken } from './auth';
import { handleSync } from './handlers/sync';
import { handlePrices } from './handlers/prices';

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);

    if (req.method === 'OPTIONS') return corsPreflight(req, env);

    if (req.method === 'GET' && url.pathname === '/api/health') {
      return jsonResponse(req, env, { ok: true, ts: Date.now() });
    }

    // Auth gate for everything else under /api/*.
    if (url.pathname.startsWith('/api/')) {
      try {
        const user = await verifyGoogleIdToken(req, env);
        if (req.method === 'POST' && url.pathname === '/api/sync') {
          return handleSync(req, env, user);
        }
        if (req.method === 'GET' && url.pathname === '/api/prices') {
          return handlePrices(req, env);
        }
        return jsonResponse(req, env, { error: 'not_found' }, { status: 404 });
      } catch (e) {
        if (e instanceof AuthError) {
          return jsonResponse(req, env, { error: e.code }, { status: e.status });
        }
        console.error('worker_error', e);
        return jsonResponse(req, env, { error: 'internal' }, { status: 500 });
      }
    }

    return jsonResponse(req, env, { error: 'not_found' }, { status: 404 });
  },
};
