import { db } from './database';
import { useAuthStore } from '@/store/useAuthStore';
import { useNetworkStore } from '@/store/useNetworkStore';
import type { Category, Investment, Tombstone, Transaction } from './types';

const API_BASE = (import.meta.env.VITE_API_BASE_URL ?? '').replace(/\/$/, '');
const STORAGE_KEY = 'budget-last-synced-at';
const PERIODIC_MS = 5 * 60 * 1000;
const DEBOUNCE_MS = 1000;
const MAX_BACKOFF_MS = 30_000;

interface SyncResponse {
  server_now: number;
  applied: { transactions: number; categories: number; investments: number; tombstones: number };
  changes: {
    transactions: Array<Omit<Transaction, 'sync_status'>>;
    categories: Array<Omit<Category, 'sync_status'>>;
    investments: Array<Omit<Investment, 'sync_status'>>;
    tombstones: Array<{ id: string; table: Tombstone['table']; record_id: string; deleted_at: number }>;
  };
}

function lastSyncedAt(): number {
  const raw = localStorage.getItem(STORAGE_KEY);
  return raw ? Number(raw) : 0;
}

function setLastSyncedAt(ts: number) {
  localStorage.setItem(STORAGE_KEY, String(ts));
}

async function pendingCount(): Promise<number> {
  const [a, b, c, d] = await Promise.all([
    db.transactions.where('sync_status').equals('pending').count(),
    db.categories.where('sync_status').equals('pending').count(),
    db.investments.where('sync_status').equals('pending').count(),
    db.tombstones.where('sync_status').equals('pending').count(),
  ]);
  return a + b + c + d;
}

let started = false;
let inFlight: Promise<void> | null = null;
let debounceTimer: ReturnType<typeof setTimeout> | null = null;
let periodicTimer: ReturnType<typeof setInterval> | null = null;
let backoff = 1000;
let dexieUnsub: (() => void) | null = null;

async function refreshPendingCount() {
  useNetworkStore.getState().setPendingCount(await pendingCount());
}

async function pushAndPull(): Promise<void> {
  const { idToken, isAuthenticated, isAllowed, signOut } = useAuthStore.getState();
  const net = useNetworkStore.getState();
  if (!API_BASE) throw new Error('VITE_API_BASE_URL is not set');
  if (!net.online) return;
  if (!idToken || !isAuthenticated() || !isAllowed()) return;

  net.setSyncState('syncing');

  const [txs, cats, invs, tombs] = await Promise.all([
    db.transactions.where('sync_status').equals('pending').toArray(),
    db.categories.where('sync_status').equals('pending').toArray(),
    db.investments.where('sync_status').equals('pending').toArray(),
    db.tombstones.where('sync_status').equals('pending').toArray(),
  ]);

  const payload = {
    transactions: txs.map(({ sync_status: _s, ...rest }) => rest),
    categories: cats.map(({ sync_status: _s, ...rest }) => rest),
    investments: invs.map(({ sync_status: _s, ...rest }) => rest),
    tombstones: tombs.map(({ sync_status: _s, ...rest }) => rest),
    last_synced_at: lastSyncedAt(),
  };

  const res = await fetch(`${API_BASE}/api/sync`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify(payload),
  });

  if (res.status === 401) {
    signOut();
    throw new Error('unauthorized');
  }
  if (!res.ok) {
    throw new Error(`sync failed: ${res.status}`);
  }

  const data = (await res.json()) as SyncResponse;

  await db.transaction(
    'rw',
    db.transactions,
    db.categories,
    db.investments,
    db.tombstones,
    async () => {
      // Mark just-pushed records as synced.
      if (txs.length) await db.transactions.bulkPut(txs.map((r) => ({ ...r, sync_status: 'synced' })));
      if (cats.length) await db.categories.bulkPut(cats.map((r) => ({ ...r, sync_status: 'synced' })));
      if (invs.length) await db.investments.bulkPut(invs.map((r) => ({ ...r, sync_status: 'synced' })));
      if (tombs.length) await db.tombstones.bulkDelete(tombs.map((t) => t.id));

      // Apply server changes (last-write-wins via updated_at, already enforced server-side).
      for (const r of data.changes.transactions) {
        const local = await db.transactions.get(r.id);
        if (!local || r.updated_at > local.updated_at) {
          await db.transactions.put({ ...r, sync_status: 'synced' });
        }
      }
      for (const r of data.changes.categories) {
        const local = await db.categories.get(r.id);
        if (!local || r.updated_at > local.updated_at) {
          await db.categories.put({ ...r, sync_status: 'synced' });
        }
      }
      for (const r of data.changes.investments) {
        const local = await db.investments.get(r.id);
        if (!local || r.updated_at > local.updated_at) {
          await db.investments.put({ ...r, sync_status: 'synced' });
        }
      }
      for (const tb of data.changes.tombstones) {
        await db.table(tb.table).delete(tb.record_id);
      }
    },
  );

  setLastSyncedAt(data.server_now);
  net.setLastSyncAt(data.server_now);
  net.setSyncState('idle');
  await refreshPendingCount();
}

async function syncNow(): Promise<void> {
  if (inFlight) return inFlight;
  inFlight = (async () => {
    try {
      await pushAndPull();
      backoff = 1000;
    } catch (err) {
      console.warn('cloudSync error', err);
      useNetworkStore.getState().setSyncState('error');
      // Retry with backoff (only if still authenticated/online).
      const next = Math.min(backoff * 2, MAX_BACKOFF_MS);
      backoff = next;
      setTimeout(() => triggerSoon(), backoff);
    } finally {
      inFlight = null;
    }
  })();
  return inFlight;
}

function triggerSoon() {
  if (debounceTimer) clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    debounceTimer = null;
    syncNow();
  }, DEBOUNCE_MS);
}

function subscribeDexieMutations(): () => void {
  const tables = [db.transactions, db.categories, db.investments, db.tombstones];
  const subs = tables.map((tbl) => {
    const onCreate = () => triggerSoon();
    const onUpdate = () => triggerSoon();
    const onDelete = () => triggerSoon();
    tbl.hook('creating', onCreate);
    tbl.hook('updating', onUpdate);
    tbl.hook('deleting', onDelete);
    return () => {
      tbl.hook('creating').unsubscribe(onCreate);
      tbl.hook('updating').unsubscribe(onUpdate);
      tbl.hook('deleting').unsubscribe(onDelete);
    };
  });
  return () => subs.forEach((u) => u());
}

function onWindowOnline() {
  syncNow();
}

export const cloudSync = {
  start(): void {
    if (started) return;
    started = true;
    refreshPendingCount();
    dexieUnsub = subscribeDexieMutations();
    window.addEventListener('online', onWindowOnline);
    periodicTimer = setInterval(() => syncNow(), PERIODIC_MS);
    // Initial sync on boot.
    syncNow();
  },
  stop(): void {
    if (!started) return;
    started = false;
    if (debounceTimer) clearTimeout(debounceTimer);
    debounceTimer = null;
    if (periodicTimer) clearInterval(periodicTimer);
    periodicTimer = null;
    window.removeEventListener('online', onWindowOnline);
    dexieUnsub?.();
    dexieUnsub = null;
  },
  syncNow,
};
