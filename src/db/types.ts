export type SyncStatus = 'pending' | 'synced' | 'error';
export type TransactionType = 'income' | 'expense';

export interface Transaction {
  id: string;             // UUID generated client-side
  date: string;           // ISO yyyy-MM-dd
  amount: number;         // always positive; sign derived from `type`
  category_id: string;
  type: TransactionType;
  description?: string;
  created_at: number;     // epoch ms
  updated_at: number;     // epoch ms — used by sync (last-write-wins)
  sync_status: SyncStatus;
}

export interface Category {
  id: string;
  name: string;
  color: string;          // hex
  type: TransactionType;  // expense or income category
  icon?: string;          // lucide icon name
  is_default?: 0 | 1;     // boolean as number for Dexie indexing
  updated_at: number;
  sync_status: SyncStatus;
}

export interface Investment {
  id: string;
  asset_symbol: string;       // e.g. AAPL, BTC
  asset_class: 'stock' | 'crypto' | 'etf' | 'fund' | 'other';
  quantity: number;
  purchase_price: number;     // unit price at purchase
  purchase_date: string;      // ISO
  currency: string;           // e.g. EUR, USD
  notes?: string;
  updated_at: number;
  sync_status: SyncStatus;
}

export interface PriceCacheEntry {
  symbol: string;             // primary key
  price: number;
  currency: string;
  fetched_at: number;         // epoch ms
}

export interface Tombstone {
  id: string;                 // `${table}:${recordId}`
  table: 'transactions' | 'categories' | 'investments';
  record_id: string;
  deleted_at: number;
  sync_status: SyncStatus;
}
