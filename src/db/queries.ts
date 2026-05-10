import { useLiveQuery } from 'dexie-react-hooks';
import { db } from './database';
import { lastNMonths, monthCursorToDate, monthRange } from '@/lib/dates';
import type { Category, Transaction, TransactionType } from './types';
import { endOfMonth, format, startOfMonth } from 'date-fns';

export function useTransactionsForMonth(monthCursor: string): Transaction[] | undefined {
  return useLiveQuery(async () => {
    const { start, end } = monthRange(monthCursor);
    return db.transactions.where('date').between(start, end, true, true).reverse().sortBy('date');
  }, [monthCursor]);
}

export interface MonthlyTotals {
  income: number;
  expense: number;
  net: number;
}

export function useMonthlyTotals(monthCursor: string): MonthlyTotals | undefined {
  return useLiveQuery(async () => {
    const { start, end } = monthRange(monthCursor);
    const rows = await db.transactions.where('date').between(start, end, true, true).toArray();
    let income = 0;
    let expense = 0;
    for (const r of rows) {
      if (r.type === 'income') income += r.amount;
      else expense += r.amount;
    }
    return { income, expense, net: income - expense };
  }, [monthCursor]);
}

export interface CategoryBreakdownRow {
  category_id: string;
  name: string;
  color: string;
  total: number;
}

export function useCategoryBreakdown(
  monthCursor: string,
  type: TransactionType,
): CategoryBreakdownRow[] | undefined {
  return useLiveQuery(async () => {
    const { start, end } = monthRange(monthCursor);
    const [rows, cats] = await Promise.all([
      db.transactions.where('date').between(start, end, true, true).and((t) => t.type === type).toArray(),
      db.categories.toArray(),
    ]);
    const byId = new Map(cats.map((c) => [c.id, c]));
    const totals = new Map<string, number>();
    for (const r of rows) {
      totals.set(r.category_id, (totals.get(r.category_id) ?? 0) + r.amount);
    }
    return Array.from(totals.entries())
      .map(([id, total]) => ({
        category_id: id,
        name: byId.get(id)?.name ?? 'Sconosciuta',
        color: byId.get(id)?.color ?? '#64748b',
        total,
      }))
      .sort((a, b) => b.total - a.total);
  }, [monthCursor, type]);
}

export interface TrendPoint {
  month: string; // 'yyyy-MM'
  label: string; // 'Gen 25'
  income: number;
  expense: number;
}

const trendLabel = new Intl.DateTimeFormat('it-IT', { month: 'short', year: '2-digit' });

export function useMonthlyTrend(n = 12): TrendPoint[] | undefined {
  return useLiveQuery(async () => {
    const months = lastNMonths(n);
    const first = format(startOfMonth(monthCursorToDate(months[0])), 'yyyy-MM-dd');
    const last = format(endOfMonth(monthCursorToDate(months[months.length - 1])), 'yyyy-MM-dd');
    const rows = await db.transactions.where('date').between(first, last, true, true).toArray();
    const buckets = new Map<string, { income: number; expense: number }>(
      months.map((m) => [m, { income: 0, expense: 0 }]),
    );
    for (const r of rows) {
      const k = r.date.slice(0, 7);
      const b = buckets.get(k);
      if (!b) continue;
      if (r.type === 'income') b.income += r.amount;
      else b.expense += r.amount;
    }
    return months.map((m) => ({
      month: m,
      label: trendLabel.format(monthCursorToDate(m)),
      income: buckets.get(m)!.income,
      expense: buckets.get(m)!.expense,
    }));
  }, [n]);
}

export function useCategories(): Category[] | undefined {
  return useLiveQuery(() => db.categories.orderBy('name').toArray(), []);
}

export function useCategoriesById(): Map<string, Category> | undefined {
  return useLiveQuery(async () => {
    const cats = await db.categories.toArray();
    return new Map(cats.map((c) => [c.id, c]));
  }, []);
}
