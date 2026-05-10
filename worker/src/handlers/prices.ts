import type { Env } from '../env';
import { jsonResponse } from '../cors';

const SYMBOL_RE = /^[A-Za-z0-9.\-]{1,12}$/;
const MAX_SYMBOLS = 25;
const CACHE_SECONDS = 15 * 60;

type AssetClass = 'stock' | 'crypto';

export async function handlePrices(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  const cls = (url.searchParams.get('class') ?? 'stock') as AssetClass;
  const symbolsRaw = (url.searchParams.get('symbols') ?? '').trim();
  if (!symbolsRaw) return jsonResponse(req, env, { error: 'missing_symbols' }, { status: 400 });

  const symbols = symbolsRaw.split(',').map((s) => s.trim()).filter(Boolean);
  if (symbols.length === 0 || symbols.length > MAX_SYMBOLS) {
    return jsonResponse(req, env, { error: 'invalid_symbol_count', max: MAX_SYMBOLS }, { status: 400 });
  }
  for (const s of symbols) {
    if (!SYMBOL_RE.test(s)) {
      return jsonResponse(req, env, { error: 'invalid_symbol', symbol: s }, { status: 400 });
    }
  }
  if (cls !== 'stock' && cls !== 'crypto') {
    return jsonResponse(req, env, { error: 'invalid_class' }, { status: 400 });
  }

  const cacheKey = new Request(`https://cache.local/prices?class=${cls}&symbols=${symbols.sort().join(',')}`);
  const cache = caches.default;
  const cached = await cache.match(cacheKey);
  if (cached) return jsonResponse(req, env, await cached.json(), { headers: { 'X-Cache': 'HIT' } });

  let payload: unknown;
  try {
    payload = cls === 'stock'
      ? await fetchYahoo(symbols)
      : await fetchCoingecko(symbols);
  } catch (e) {
    return jsonResponse(
      req, env,
      { error: 'upstream_failure', message: e instanceof Error ? e.message : 'unknown' },
      { status: 502 },
    );
  }

  const body = JSON.stringify(payload);
  await cache.put(
    cacheKey,
    new Response(body, {
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': `public, max-age=${CACHE_SECONDS}`,
      },
    }),
  );
  return jsonResponse(req, env, payload, { headers: { 'X-Cache': 'MISS' } });
}

interface QuoteOut {
  symbol: string;
  price: number;
  currency: string;
  ts: number;
}

async function fetchYahoo(symbols: string[]): Promise<{ quotes: QuoteOut[] }> {
  const url = `https://query1.finance.yahoo.com/v7/finance/quote?symbols=${encodeURIComponent(symbols.join(','))}`;
  const r = await fetch(url, { headers: { 'User-Agent': 'budget-website/1.0' } });
  if (!r.ok) throw new Error(`yahoo ${r.status}`);
  const j = (await r.json()) as { quoteResponse?: { result?: Array<Record<string, unknown>> } };
  const out: QuoteOut[] = (j.quoteResponse?.result ?? []).map((q) => ({
    symbol: String(q.symbol),
    price: Number(q.regularMarketPrice ?? q.postMarketPrice ?? q.preMarketPrice ?? 0),
    currency: String(q.currency ?? 'USD'),
    ts: Number(q.regularMarketTime ?? Math.floor(Date.now() / 1000)) * 1000,
  }));
  return { quotes: out };
}

async function fetchCoingecko(symbols: string[]): Promise<{ quotes: QuoteOut[] }> {
  // CoinGecko's `simple/price` expects ids (e.g. "bitcoin"), not tickers — caller must use ids.
  const ids = encodeURIComponent(symbols.map((s) => s.toLowerCase()).join(','));
  const url = `https://api.coingecko.com/api/v3/simple/price?ids=${ids}&vs_currencies=eur,usd&include_last_updated_at=true`;
  const r = await fetch(url);
  if (!r.ok) throw new Error(`coingecko ${r.status}`);
  const j = (await r.json()) as Record<string, { eur?: number; usd?: number; last_updated_at?: number }>;
  const out: QuoteOut[] = [];
  for (const [id, data] of Object.entries(j)) {
    const price = data.eur ?? data.usd ?? 0;
    out.push({
      symbol: id,
      price,
      currency: data.eur != null ? 'EUR' : 'USD',
      ts: (data.last_updated_at ?? Math.floor(Date.now() / 1000)) * 1000,
    });
  }
  return { quotes: out };
}
