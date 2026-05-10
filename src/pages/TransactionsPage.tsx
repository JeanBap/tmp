import { useState } from 'react';
import { Plus, Upload } from 'lucide-react';
import { MonthSwitcher } from '@/components/dashboard/MonthSwitcher';
import { Modal } from '@/components/ui/Modal';
import { TransactionForm } from '@/components/transactions/TransactionForm';
import { TransactionList } from '@/components/transactions/TransactionList';
import { CsvImportDialog } from '@/components/transactions/CsvImportDialog';

export function TransactionsPage() {
  const [adding, setAdding] = useState(false);
  const [importing, setImporting] = useState(false);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <h1 className="text-2xl font-semibold">Transazioni</h1>
        <MonthSwitcher />
      </div>

      <div className="flex gap-2">
        <button
          type="button"
          onClick={() => setAdding(true)}
          className="inline-flex items-center gap-2 rounded-md bg-brand-600 hover:bg-brand-700 px-4 py-2 text-sm font-medium text-white"
        >
          <Plus className="size-4" /> Aggiungi
        </button>
        <button
          type="button"
          onClick={() => setImporting(true)}
          className="inline-flex items-center gap-2 rounded-md border border-slate-700 hover:bg-slate-800 px-4 py-2 text-sm font-medium"
        >
          <Upload className="size-4" /> Importa CSV
        </button>
      </div>

      <TransactionList />

      <Modal open={adding} onClose={() => setAdding(false)} title="Nuova transazione">
        <TransactionForm onDone={() => setAdding(false)} />
      </Modal>

      <CsvImportDialog open={importing} onClose={() => setImporting(false)} />
    </div>
  );
}
