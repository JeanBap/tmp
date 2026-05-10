import { ArrowDownCircle, ArrowUpCircle, Wallet } from 'lucide-react';
import { useMonthlyTotals } from '@/db/queries';
import { formatCurrency } from '@/lib/format';
import { useUIStore } from '@/store/useUIStore';

function Card({
  label,
  value,
  Icon,
  tone,
}: {
  label: string;
  value: number;
  Icon: typeof ArrowUpCircle;
  tone: 'income' | 'expense' | 'net';
}) {
  const toneCls =
    tone === 'income'
      ? 'text-emerald-400'
      : tone === 'expense'
      ? 'text-rose-400'
      : value >= 0
      ? 'text-sky-400'
      : 'text-amber-400';
  return (
    <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
      <div className="flex items-center gap-2 text-xs uppercase tracking-wide text-slate-400">
        <Icon className={`size-4 ${toneCls}`} />
        {label}
      </div>
      <div className={`mt-2 text-2xl font-semibold tabular-nums ${toneCls}`}>
        {formatCurrency(value)}
      </div>
    </div>
  );
}

export function SummaryCards() {
  const monthCursor = useUIStore((s) => s.monthCursor);
  const totals = useMonthlyTotals(monthCursor);
  const t = totals ?? { income: 0, expense: 0, net: 0 };
  return (
    <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
      <Card label="Entrate" value={t.income} Icon={ArrowUpCircle} tone="income" />
      <Card label="Uscite" value={t.expense} Icon={ArrowDownCircle} tone="expense" />
      <Card label="Saldo" value={t.net} Icon={Wallet} tone="net" />
    </div>
  );
}
