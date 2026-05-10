import Dexie, { type Table } from 'dexie';
import type {
  Category,
  Investment,
  PriceCacheEntry,
  Tombstone,
  Transaction,
} from './types';

class BudgetDB extends Dexie {
  transactions!: Table<Transaction, string>;
  categories!: Table<Category, string>;
  investments!: Table<Investment, string>;
  prices!: Table<PriceCacheEntry, string>;
  tombstones!: Table<Tombstone, string>;

  constructor() {
    super('budget-website');

    this.version(1).stores({
      // `&` = unique primary key; non-prefixed fields = indexes
      transactions: '&id, date, type, category_id, sync_status, updated_at',
      categories: '&id, name, type, sync_status, updated_at',
      investments: '&id, asset_symbol, asset_class, sync_status, updated_at',
      prices: '&symbol, fetched_at',
      tombstones: '&id, table, sync_status, deleted_at',
    });

    // v2: add import_hash index on transactions for CSV dedupe.
    this.version(2).stores({
      transactions: '&id, date, type, category_id, sync_status, updated_at, import_hash',
    });
  }
}

export const db = new BudgetDB();

const DEFAULT_CATEGORIES: Omit<Category, 'updated_at' | 'sync_status'>[] = [
  { id: 'cat-food', name: 'Spesa & cibo', color: '#22c55e', type: 'expense', icon: 'ShoppingCart', is_default: 1 },
  { id: 'cat-transport', name: 'Trasporti', color: '#3b82f6', type: 'expense', icon: 'Car', is_default: 1 },
  { id: 'cat-bills', name: 'Bollette', color: '#f59e0b', type: 'expense', icon: 'Zap', is_default: 1 },
  { id: 'cat-rent', name: 'Affitto / Mutuo', color: '#a855f7', type: 'expense', icon: 'Home', is_default: 1 },
  { id: 'cat-leisure', name: 'Svago', color: '#ec4899', type: 'expense', icon: 'Gamepad2', is_default: 1 },
  { id: 'cat-health', name: 'Salute', color: '#ef4444', type: 'expense', icon: 'HeartPulse', is_default: 1 },
  { id: 'cat-other-exp', name: 'Altro', color: '#64748b', type: 'expense', icon: 'MoreHorizontal', is_default: 1 },
  { id: 'cat-salary', name: 'Stipendio', color: '#10b981', type: 'income', icon: 'Banknote', is_default: 1 },
  { id: 'cat-bonus', name: 'Bonus', color: '#14b8a6', type: 'income', icon: 'Gift', is_default: 1 },
  { id: 'cat-other-inc', name: 'Altre entrate', color: '#0ea5e9', type: 'income', icon: 'PiggyBank', is_default: 1 },
];

export async function seedDefaults(): Promise<void> {
  const count = await db.categories.count();
  if (count > 0) return;
  const now = Date.now();
  await db.categories.bulkAdd(
    DEFAULT_CATEGORIES.map((c) => ({ ...c, updated_at: now, sync_status: 'pending' as const })),
  );
}

export function newId(): string {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return crypto.randomUUID();
  }
  return `id-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
}
