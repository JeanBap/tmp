import { useState, type FormEvent } from 'react';
import { transactionsRepo } from '@/db/repositories';
import { useCategories } from '@/db/queries';
import type { Transaction, TransactionType } from '@/db/types';

interface Props {
  initial?: Transaction;
  onDone: () => void;
}

export function TransactionForm({ initial, onDone }: Props) {
  const cats = useCategories();
  const today = new Date().toISOString().slice(0, 10);
  const [date, setDate] = useState(initial?.date ?? today);
  const [amount, setAmount] = useState(initial ? String(initial.amount) : '');
  const [type, setType] = useState<TransactionType>(initial?.type ?? 'expense');
  const [categoryId, setCategoryId] = useState(initial?.category_id ?? '');
  const [description, setDescription] = useState(initial?.description ?? '');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const filteredCats = (cats ?? []).filter((c) => c.type === type);

  // Auto-pick first matching category when switching type, if current is invalid.
  const validCategory = filteredCats.some((c) => c.id === categoryId);
  if (!validCategory && filteredCats.length > 0 && categoryId !== filteredCats[0].id) {
    queueMicrotask(() => setCategoryId(filteredCats[0].id));
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    const parsed = Number(amount.replace(',', '.'));
    if (!Number.isFinite(parsed) || parsed <= 0) {
      setError("Importo non valido (deve essere > 0).");
      return;
    }
    if (!categoryId) {
      setError('Seleziona una categoria.');
      return;
    }
    setSubmitting(true);
    try {
      if (initial) {
        await transactionsRepo.update(initial.id, {
          date,
          amount: parsed,
          type,
          category_id: categoryId,
          description: description || undefined,
        });
      } else {
        await transactionsRepo.add({
          date,
          amount: parsed,
          type,
          category_id: categoryId,
          description: description || undefined,
        });
      }
      onDone();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Errore sconosciuto');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-2">
        <button
          type="button"
          onClick={() => setType('expense')}
          className={`rounded-md py-2 text-sm font-medium border transition-colors ${
            type === 'expense'
              ? 'bg-rose-500/15 border-rose-500/40 text-rose-200'
              : 'border-slate-700 text-slate-300 hover:bg-slate-800'
          }`}
        >
          Uscita
        </button>
        <button
          type="button"
          onClick={() => setType('income')}
          className={`rounded-md py-2 text-sm font-medium border transition-colors ${
            type === 'income'
              ? 'bg-emerald-500/15 border-emerald-500/40 text-emerald-200'
              : 'border-slate-700 text-slate-300 hover:bg-slate-800'
          }`}
        >
          Entrata
        </button>
      </div>

      <label className="block text-sm">
        <span className="text-slate-300">Data</span>
        <input
          type="date"
          value={date}
          onChange={(e) => setDate(e.target.value)}
          required
          className="mt-1 block w-full rounded-md border border-slate-700 bg-slate-950 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none"
        />
      </label>

      <label className="block text-sm">
        <span className="text-slate-300">Importo (€)</span>
        <input
          type="text"
          inputMode="decimal"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          required
          placeholder="0,00"
          className="mt-1 block w-full rounded-md border border-slate-700 bg-slate-950 px-3 py-2 text-sm tabular-nums focus:border-brand-500 focus:outline-none"
        />
      </label>

      <label className="block text-sm">
        <span className="text-slate-300">Categoria</span>
        <select
          value={categoryId}
          onChange={(e) => setCategoryId(e.target.value)}
          required
          className="mt-1 block w-full rounded-md border border-slate-700 bg-slate-950 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none"
        >
          {filteredCats.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
      </label>

      <label className="block text-sm">
        <span className="text-slate-300">Descrizione (opzionale)</span>
        <input
          type="text"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          className="mt-1 block w-full rounded-md border border-slate-700 bg-slate-950 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none"
        />
      </label>

      {error && <p className="text-sm text-rose-400">{error}</p>}

      <button
        type="submit"
        disabled={submitting}
        className="w-full rounded-md bg-brand-600 hover:bg-brand-700 disabled:opacity-50 px-4 py-2 text-sm font-medium text-white transition-colors"
      >
        {submitting ? 'Salvataggio…' : initial ? 'Aggiorna' : 'Aggiungi'}
      </button>
    </form>
  );
}
