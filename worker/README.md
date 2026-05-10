# budget-website Cloudflare Worker

API + sync backend for the PWA. Auth is Google ID-token (JWKS) restricted to `ALLOWED_EMAIL`.

## Endpoints

| Method | Path          | Auth | Notes                                                |
| ------ | ------------- | :--: | ---------------------------------------------------- |
| GET    | `/api/health` |  no  | `{ok:true}`                                          |
| POST   | `/api/sync`   | yes  | Push/pull JSON; last-write-wins via `updated_at`     |
| GET    | `/api/prices` | yes  | Proxy to Yahoo (`class=stock`) / CoinGecko (`crypto`)|

## First-time setup

```bash
cd worker
npm install
npx wrangler login
npx wrangler d1 create budget
# Paste the resulting database_id into wrangler.toml
npm run db:migrate:local      # apply locally
npm run dev                   # http://127.0.0.1:8787
```

Set `GOOGLE_CLIENT_ID` and `ALLOWED_ORIGIN` in `wrangler.toml` (or via `wrangler secret put` for the client id) before deploying. `ALLOWED_EMAIL` is `francescoceruzzi@gmail.com`.

## Deploy

```bash
npm run db:migrate           # apply migrations to remote D1
npm run deploy
```

## Smoke tests

```bash
curl -s http://127.0.0.1:8787/api/health
# 401 — no token
curl -s -X POST http://127.0.0.1:8787/api/sync -d '{}'
# 401 — bad token
curl -s -X POST http://127.0.0.1:8787/api/sync -H 'Authorization: Bearer abc' -d '{}'
```

## Security notes

- JWT is verified against `https://www.googleapis.com/oauth2/v3/certs` with `jose.jwtVerify`,
  enforcing `iss`, `aud=GOOGLE_CLIENT_ID`, `exp`, and `email_verified=true`.
- CORS reflects `Origin` only when it equals `ALLOWED_ORIGIN` — never `*`.
- All D1 statements are parameterised; `user_email` is taken from the verified token,
  never from the request body.
