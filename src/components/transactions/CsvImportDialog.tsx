import { useMemo, useState } from 'react';
import Papa from 'papaparse';
import { Modal } from '@/components/ui/Modal';
import { db, newId } from '@/db/database';
import { useCategories } from '@/db/queries';
import { sha1Hex } from '@/lib/hash';
import type { Transaction } from '@/db/types';

interface Props {
  open: boolean;
  onClose: () => void;
}

type Row = Record<string, string>;
type FieldKey = 'date' | 'amount' | 'description' | 'type';

const HEADER_ALIASES: Record<FieldKey, string[]> = {
  date: ['date', 'data', 'data operazione', 'data valuta'],
  amount: ['amount', 'importo', 'valore', 'totale'],
  description: ['description', 'descrizione', 'causale', 'note'],
  type: ['type', 'tipo', 'segno'],
};

function autoMap(headers: string[]): Record<FieldKey, string | ''> {
  const lower = headers.map((h) => h.toLowerCase().trim());
  const pick = (aliases: string[]) => {
    for (const a of aliases) {
      const idx = lower.indexOf(a);
      if (idx >= 0) return headers[idx];
    }
    return '';
  };
  return {
    date: pick(HEADER_ALIASES.date),
    amount: pick(HEADER_ALIASES.amount),
    description: pick(HEADER_ALIASES.description),
    type: pick(HEADER_ALIASES.type),
  };
}

function parseAmount(raw: string): number | null {
  if (!raw) return null;
  // Remove currency symbols and thousands separator (italian: '.'), then swap decimal ','.
  const cleaned = raw.replace(/[^\d,.\-]/g, '').replace(/\.(?=\d{3}(\D|$))/g, '').replace(',', '.');
  const n = Number(cleaned);
  return Number.isFinite(n) ? n : null;
}

function parseDate(raw: string): string | null {
  if (!raw) return null;
  const trimmed = raw.trim();
  // ISO yyyy-MM-dd
  if (/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) return trimmed;
  // dd/MM/yyyy or dd-MM-yyyy
  const m = trimmed.match(/^(\d{2})[/-](\d{2})[/-](\d{4})$/);
  if (m) return `${m[3]}-${m[2]}-${m[1]}`;
  const d = new Date(trimmed);
  if (!isNaN(d.getTime())) return d.toISOString().slice(0, 10);
  return null;
}

export function CsvImportDialog({ open, onClose }: Props) {
  const cats = useCategories();
  const defaultExpenseCat = cats?.find((c) => c.id === 'cat-other-exp')?.id ?? cats?.find((c) => c.type === 'expense')?.id ?? '';
  const defaultIncomeCat = cats?.find((c) => c.id === 'cat-other-inc')?.id ?? cats?.find((c) => c.type === 'income')?.id ?? '';

  const [rows, setRows] = useState<Row[] | null>(null);
  const [headers, setHeaders] = useState<string[]>([]);
  const [mapping, setMapping] = useState<Record<FieldKey, string | ''>>({
    date: '',
    amount: '',
    description: '',
    type: '',
  });
  const [importing, setImporting] = useState(false);
  const [result, setResult] = useState<{ inserted: number; skipped: number; invalid: number } | null>(null);

  function reset() {
    setRows(null);
    setHeaders([]);
    setMapping({ date: '', amount: '', description: '', type: '' });
    setResult(null);
  }

  function handleFile(file: File) {
    Papa.parse<Row>(file, {
      header: true,
      skipEmptyLines: true,
      complete: (res) => {
        const hdrs = res.meta.fields ?? [];
        setHeaders(hdrs);
        setRows(res.data);
        setMapping(autoMap(hdrs));
      },
    });
  }

  const preview = useMemo(() => (rows ?? []).slice(0, 5), [rows]);

  async function runImport() {
    if (!rows || !mapping.date || !mapping.amount) return;
    setImporting(true);
    let inserted = 0;
    let skipped = 0;
    let invalid = 0;
    const now = Date.now();
    const records: Transaction[] = [];

    for (const r of rows) {
      const date = parseDate(r[mapping.date] ?? '');
      const amountRaw = parseAmount(r[mapping.amount] ?? '');
      if (!date || amountRaw === null) {
        invalid++;
        continue;
      }
      const description = mapping.description ? r[mapping.description] ?? '' : '';
      const explicitType = mapping.type ? (r[mapping.type] ?? '').toLowerCase() : '';
      const type: Transaction['type'] =
        explicitType.startsWith('e') || explicitType.startsWith('inc') || explicitType === '+'
          ? 'income'
          : amountRaw > 0 && !explicitType
          ? 'income'
          : 'expense';
      const amount = Math.abs(amountRaw);
      const hash = await sha1Hex(`${date}|${amount.toFixed(2)}|${description.trim().toLowerCase()}`);

      records.push({
        id: newId(),
        date,
        amount,
        type,
        category_id: type === 'expense' ? defaultExpenseCat : defaultIncomeCat,
        description: description || undefined,
        import_hash: hash,
        created_at: now,
        updated_at: now,
        sync_status: 'pending',
      });
    }

    await db.transaction('rw', db.transactions, async () => {
      for (const r of records) {
        const existing = r.import_hash
          ? await db.transactions.where('import_hash').equals(r.import_hash).first()
          : undefined;
        if (existing) {
          skipped++;
          continue;
        }
        await db.transactions.add(r);
        inserted++;
      }
    });

    setResult({ inserted, skipped, invalid });
    setImporting(false);
  }

  const ready = rows && mapping.date && mapping.amount && defaultExpenseCat;

  return (
    <Modal open={open} onClose={() => { reset(); onClose(); }} title="Importa CSV" size="lg">
      {!rows && (
        <label className="block">
          <span className="text-sm text-slate-300">
            Carica un file CSV con colonne tipo <code className="text-slate-100">data, importo, descrizione</code> (header nella prima riga).
          </span>
          <input
            type="file"
            accept=".csv,text/csv"
            onChange={(e) => e.target.files && e.target.files[0] && handleFile(e.target.files[0])}
            className="mt-3 block w-full text-sm file:mr-3 file:rounded-md file:border-0 file:bg-brand-600 file:px-3 file:py-2 file:text-sm file:font-medium file:text-white"
          />
        </label>
      )}

      {rows && !result && (
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            {(['date', 'amount', 'description', 'type'] as FieldKey[]).map((f) => (
              <label key={f} className="block text-sm">
                <span className="text-slate-300 capitalize">{f}{(f === 'date' || f === 'amount') && ' *'}</span>
                <select
                  value={mapping[f]}
                  onChange={(e) => setMapping((m) => ({ ...m, [f]: e.target.value }))}
                  className="mt-1 block w-full rounded-md border border-slate-700 bg-slate-950 px-2 py-1.5 text-sm"
                >
                  <option value="">— ignora —</option>
                  {headers.map((h) => (
                    <option key={h} value={h}>{h}</option>
                  ))}
                </select>
              </label>
            ))}
          </div>

          <div className="overflow-x-auto rounded-md border border-slate-800">
            <table className="w-full text-xs">
              <thead className="bg-slate-800/60">
                <tr>
                  {headers.map((h) => (
                    <th key={h} className="px-2 py-1 text-left font-medium">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {preview.map((r, i) => (
                  <tr key={i} className="border-t border-slate-800">
                    {headers.map((h) => (
                      <td key={h} className="px-2 py-1 truncate max-w-[12rem]">{r[h]}</td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="text-xs text-slate-400">
            Anteprima delle prime {preview.length} righe su {rows.length}. Le righe duplicate (stesso giorno + importo + descrizione) verranno ignorate.
          </p>

          <div className="flex gap-2">
            <button
              type="button"
              onClick={reset}
              className="px-4 py-2 rounded-md border border-slate-700 text-sm hover:bg-slate-800"
            >
              Annulla
            </button>
            <button
              type="button"
              disabled={!ready || importing}
              onClick={runImport}
              className="flex-1 px-4 py-2 rounded-md bg-brand-600 hover:bg-brand-700 disabled:opacity-50 text-sm font-medium text-white"
            >
              {importing ? 'Importazione…' : `Importa ${rows.length} righe`}
            </button>
          </div>
        </div>
      )}

      {result && (
        <div className="space-y-3 text-sm">
          <p>
            <span className="text-emerald-400 font-semibold">{result.inserted}</span> nuove transazioni importate.
          </p>
          {result.skipped > 0 && (
            <p>
              <span className="text-amber-400 font-semibold">{result.skipped}</span> duplicati ignorati.
            </p>
          )}
          {result.invalid > 0 && (
            <p>
              <span className="text-rose-400 font-semibold">{result.invalid}</span> righe scartate (data o importo non valido).
            </p>
          )}
          <button
            type="button"
            onClick={() => { reset(); onClose(); }}
            className="w-full px-4 py-2 rounded-md bg-brand-600 hover:bg-brand-700 text-sm font-medium text-white"
          >
            Chiudi
          </button>
        </div>
      )}
    </Modal>
  );
}
