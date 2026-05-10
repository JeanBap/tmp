import { createRemoteJWKSet, jwtVerify, type JWTPayload } from 'jose';
import type { Env } from './env';

// Module-scoped JWKS cache: persists across invocations within the same isolate.
const JWKS = createRemoteJWKSet(new URL('https://www.googleapis.com/oauth2/v3/certs'), {
  cooldownDuration: 30_000,
  cacheMaxAge: 24 * 60 * 60 * 1000,
});

export interface VerifiedUser {
  email: string;
  sub: string;
  name?: string;
  picture?: string;
}

export class AuthError extends Error {
  constructor(public status: number, public code: string, message: string) {
    super(message);
  }
}

export async function verifyGoogleIdToken(req: Request, env: Env): Promise<VerifiedUser> {
  const auth = req.headers.get('Authorization') ?? '';
  const m = /^Bearer\s+(.+)$/i.exec(auth);
  if (!m) throw new AuthError(401, 'missing_token', 'Authorization Bearer token is required');
  const token = m[1].trim();

  if (!env.GOOGLE_CLIENT_ID || env.GOOGLE_CLIENT_ID.startsWith('REPLACE_')) {
    throw new AuthError(500, 'misconfigured', 'GOOGLE_CLIENT_ID is not configured');
  }

  let payload: JWTPayload;
  try {
    ({ payload } = await jwtVerify(token, JWKS, {
      issuer: ['accounts.google.com', 'https://accounts.google.com'],
      audience: env.GOOGLE_CLIENT_ID,
    }));
  } catch (e) {
    throw new AuthError(401, 'invalid_token', e instanceof Error ? e.message : 'invalid token');
  }

  if (payload.email_verified !== true) {
    throw new AuthError(401, 'email_unverified', 'email not verified by Google');
  }
  const email = String(payload.email ?? '').toLowerCase();
  const allowed = env.ALLOWED_EMAIL.toLowerCase();
  if (!allowed) throw new AuthError(500, 'misconfigured', 'ALLOWED_EMAIL is not configured');
  if (email !== allowed) {
    throw new AuthError(403, 'forbidden_email', 'this email is not allowed');
  }

  return {
    email,
    sub: String(payload.sub),
    name: payload.name as string | undefined,
    picture: payload.picture as string | undefined,
  };
}
