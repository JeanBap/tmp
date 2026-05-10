import type { Env } from '../env';
import { jsonResponse } from '../cors';
import type { VerifiedUser } from '../auth';

interface BaseRecord {
  id: string;
  updated_at: number;
}

interface TransactionRow extends BaseRecord {
  date: string;
  amount: number;
  category_id: string;
  type: 'income' | 'expense';
  description?: string | null;
  import_hash?: string | null;
  created_at: number;
}
interface CategoryRow extends BaseRecord {
  name: string;
  color: string;
  type: 'income' | 'expense';
  icon?: string | null;
  is_default?: 0 | 1;
}
interface InvestmentRow extends BaseRecord {
  asset_symbol: string;
  asset_class: string;
  quantity: number;
  purchase_price: number;
  purchase_date: string;
  currency: string;
  notes?: string | null;
}
interface TombstoneRow {
  id: string;
  table: 'transactions' | 'categories' | 'investments';
  record_id: string;
  deleted_at: number;
}

interface SyncPayload {
  transactions?: TransactionRow[];
  categories?: CategoryRow[];
  investments?: InvestmentRow[];
  tombstones?: TombstoneRow[];
  last_synced_at?: number;
}

interface ChangesSince {
  transactions: TransactionRow[];
  categories: CategoryRow[];
  investments: InvestmentRow[];
  tombstones: TombstoneRow[];
}

const MAX_BATCH = 1000;

export async function handleSync(req: Request, env: Env, user: VerifiedUser): Promise<Response> {
  let body: SyncPayload;
  try {
    body = await req.json();
  } catch {
    return jsonResponse(req, env, { error: 'invalid_json' }, { status: 400 });
  }

  const txs = body.transactions ?? [];
  const cats = body.categories ?? [];
  const invs = body.investments ?? [];
  const tombs = body.tombstones ?? [];
  if (txs.length + cats.length + invs.length + tombs.length > MAX_BATCH) {
    return jsonResponse(req, env, { error: 'batch_too_large', max: MAX_BATCH }, { status: 413 });
  }

  const stmts: D1PreparedStatement[] = [];

  for (const t of txs) {
    stmts.push(
      env.DB.prepare(
        `INSERT INTO transactions (id,user_email,date,amount,category_id,type,description,import_hash,created_at,updated_at)
         VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10)
         ON CONFLICT(id) DO UPDATE SET
           date=excluded.date, amount=excluded.amount, category_id=excluded.category_id,
           type=excluded.type, description=excluded.description, import_hash=excluded.import_hash,
           updated_at=excluded.updated_at
         WHERE excluded.updated_at > transactions.updated_at`,
      ).bind(
        t.id, user.email, t.date, t.amount, t.category_id, t.type,
        t.description ?? null, t.import_hash ?? null, t.created_at, t.updated_at,
      ),
    );
  }
  for (const c of cats) {
    stmts.push(
      env.DB.prepare(
        `INSERT INTO categories (id,user_email,name,color,type,icon,is_default,updated_at)
         VALUES (?1,?2,?3,?4,?5,?6,?7,?8)
         ON CONFLICT(id) DO UPDATE SET
           name=excluded.name, color=excluded.color, type=excluded.type,
           icon=excluded.icon, is_default=excluded.is_default, updated_at=excluded.updated_at
         WHERE excluded.updated_at > categories.updated_at`,
      ).bind(c.id, user.email, c.name, c.color, c.type, c.icon ?? null, c.is_default ?? 0, c.updated_at),
    );
  }
  for (const i of invs) {
    stmts.push(
      env.DB.prepare(
        `INSERT INTO investments (id,user_email,asset_symbol,asset_class,quantity,purchase_price,purchase_date,currency,notes,updated_at)
         VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10)
         ON CONFLICT(id) DO UPDATE SET
           asset_symbol=excluded.asset_symbol, asset_class=excluded.asset_class,
           quantity=excluded.quantity, purchase_price=excluded.purchase_price,
           purchase_date=excluded.purchase_date, currency=excluded.currency,
           notes=excluded.notes, updated_at=excluded.updated_at
         WHERE excluded.updated_at > investments.updated_at`,
      ).bind(
        i.id, user.email, i.asset_symbol, i.asset_class, i.quantity, i.purchase_price,
        i.purchase_date, i.currency, i.notes ?? null, i.updated_at,
      ),
    );
  }
  for (const tb of tombs) {
    // Delete the record (scoped by user) and persist the tombstone.
    stmts.push(
      env.DB.prepare(`DELETE FROM ${tb.table} WHERE id = ?1 AND user_email = ?2`).bind(tb.record_id, user.email),
    );
    stmts.push(
      env.DB.prepare(
        `INSERT INTO tombstones (id,user_email,table_name,record_id,deleted_at)
         VALUES (?1,?2,?3,?4,?5)
         ON CONFLICT(id) DO UPDATE SET deleted_at=excluded.deleted_at
         WHERE excluded.deleted_at > tombstones.deleted_at`,
      ).bind(tb.id, user.email, tb.table, tb.record_id, tb.deleted_at),
    );
  }

  if (stmts.length > 0) {
    await env.DB.batch(stmts);
  }

  // Pull-side: return server changes since `last_synced_at`.
  const since = Number.isFinite(body.last_synced_at) ? body.last_synced_at! : 0;
  const changes = await loadChangesSince(env, user.email, since);

  return jsonResponse(req, env, {
    server_now: Date.now(),
    applied: {
      transactions: txs.length,
      categories: cats.length,
      investments: invs.length,
      tombstones: tombs.length,
    },
    changes,
  });
}

async function loadChangesSince(env: Env, email: string, since: number): Promise<ChangesSince> {
  const [txs, cats, invs, tombs] = await Promise.all([
    env.DB.prepare(
      'SELECT id,date,amount,category_id,type,description,import_hash,created_at,updated_at FROM transactions WHERE user_email = ?1 AND updated_at > ?2',
    ).bind(email, since).all<TransactionRow>(),
    env.DB.prepare(
      'SELECT id,name,color,type,icon,is_default,updated_at FROM categories WHERE user_email = ?1 AND updated_at > ?2',
    ).bind(email, since).all<CategoryRow>(),
    env.DB.prepare(
      'SELECT id,asset_symbol,asset_class,quantity,purchase_price,purchase_date,currency,notes,updated_at FROM investments WHERE user_email = ?1 AND updated_at > ?2',
    ).bind(email, since).all<InvestmentRow>(),
    env.DB.prepare(
      'SELECT id,table_name as "table",record_id,deleted_at FROM tombstones WHERE user_email = ?1 AND deleted_at > ?2',
    ).bind(email, since).all<TombstoneRow>(),
  ]);

  return {
    transactions: txs.results ?? [],
    categories: cats.results ?? [],
    investments: invs.results ?? [],
    tombstones: tombs.results ?? [],
  };
}
