import { useState } from 'react';
import { Pencil, Trash2 } from 'lucide-react';
import { useCategoriesById, useTransactionsForMonth } from '@/db/queries';
import { transactionsRepo } from '@/db/repositories';
import type { Transaction, TransactionType } from '@/db/types';
import { useUIStore } from '@/store/useUIStore';
import { formatCurrency, formatDate } from '@/lib/format';
import { Modal } from '@/components/ui/Modal';
import { TransactionForm } from './TransactionForm';

type Filter = 'all' | TransactionType;

export function TransactionList() {
  const monthCursor = useUIStore((s) => s.monthCursor);
  const txs = useTransactionsForMonth(monthCursor);
  const cats = useCategoriesById();
  const [filter, setFilter] = useState<Filter>('all');
  const [editing, setEditing] = useState<Transaction | null>(null);

  const visible = (txs ?? []).filter((t) => filter === 'all' || t.type === filter);

  const FilterButton = ({ value, label }: { value: Filter; label: string }) => (
    <button
      type="button"
      onClick={() => setFilter(value)}
      className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${
        filter === value ? 'bg-brand-600 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
      }`}
    >
      {label}
    </button>
  );

  return (
    <>
      <div className="flex gap-2 mb-3">
        <FilterButton value="all" label="Tutte" />
        <FilterButton value="expense" label="Uscite" />
        <FilterButton value="income" label="Entrate" />
      </div>

      <ul className="rounded-xl border border-slate-800 bg-slate-900/60 divide-y divide-slate-800">
        {visible.length === 0 && (
          <li className="px-4 py-10 text-center text-sm text-slate-400">
            Nessuna transazione. Usa "Aggiungi" o "Importa CSV" per iniziare.
          </li>
        )}
        {visible.map((t) => {
          const cat = cats?.get(t.category_id);
          const sign = t.type === 'expense' ? -1 : 1;
          const amountCls = t.type === 'expense' ? 'text-rose-400' : 'text-emerald-400';
          return (
            <li key={t.id} className="flex items-center gap-3 px-4 py-3">
              <span
                className="size-2.5 shrink-0 rounded-full"
                style={{ background: cat?.color ?? '#64748b' }}
              />
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between gap-3">
                  <span className="truncate font-medium text-sm">
                    {t.description || cat?.name || 'Transazione'}
                  </span>
                  <span className={`text-sm font-semibold tabular-nums ${amountCls}`}>
                    {formatCurrency(sign * t.amount)}
                  </span>
                </div>
                <div className="text-xs text-slate-400 flex gap-2">
                  <span>{formatDate(t.date)}</span>
                  <span>·</span>
                  <span className="truncate">{cat?.name ?? 'Sconosciuta'}</span>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setEditing(t)}
                className="p-1.5 rounded-md text-slate-400 hover:text-white hover:bg-slate-800"
                aria-label="Modifica"
              >
                <Pencil className="size-4" />
              </button>
              <button
                type="button"
                onClick={() => {
                  if (confirm('Eliminare questa transazione?')) {
                    transactionsRepo.remove(t.id);
                  }
                }}
                className="p-1.5 rounded-md text-slate-400 hover:text-rose-400 hover:bg-slate-800"
                aria-label="Elimina"
              >
                <Trash2 className="size-4" />
              </button>
            </li>
          );
        })}
      </ul>

      <Modal open={!!editing} onClose={() => setEditing(null)} title="Modifica transazione">
        {editing && <TransactionForm initial={editing} onDone={() => setEditing(null)} />}
      </Modal>
    </>
  );
}
