import { db, newId } from './database';
import type { Investment, Transaction } from './types';

const now = () => Date.now();

export const transactionsRepo = {
  async add(input: Omit<Transaction, 'id' | 'created_at' | 'updated_at' | 'sync_status'>) {
    const ts = now();
    const record: Transaction = {
      ...input,
      id: newId(),
      created_at: ts,
      updated_at: ts,
      sync_status: 'pending',
    };
    await db.transactions.add(record);
    return record;
  },

  async update(id: string, patch: Partial<Omit<Transaction, 'id' | 'created_at'>>) {
    await db.transactions.update(id, { ...patch, updated_at: now(), sync_status: 'pending' });
  },

  async remove(id: string) {
    await db.transaction('rw', db.transactions, db.tombstones, async () => {
      await db.transactions.delete(id);
      await db.tombstones.put({
        id: `transactions:${id}`,
        table: 'transactions',
        record_id: id,
        deleted_at: now(),
        sync_status: 'pending',
      });
    });
  },
};

export const investmentsRepo = {
  async add(input: Omit<Investment, 'id' | 'updated_at' | 'sync_status'>) {
    const record: Investment = {
      ...input,
      id: newId(),
      updated_at: now(),
      sync_status: 'pending',
    };
    await db.investments.add(record);
    return record;
  },

  async update(id: string, patch: Partial<Omit<Investment, 'id'>>) {
    await db.investments.update(id, { ...patch, updated_at: now(), sync_status: 'pending' });
  },

  async remove(id: string) {
    await db.transaction('rw', db.investments, db.tombstones, async () => {
      await db.investments.delete(id);
      await db.tombstones.put({
        id: `investments:${id}`,
        table: 'investments',
        record_id: id,
        deleted_at: now(),
        sync_status: 'pending',
      });
    });
  },
};
