import {
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { useMonthlyTrend } from '@/db/queries';
import { formatCurrency } from '@/lib/format';

export function MonthlyTrendChart() {
  const data = useMonthlyTrend(12);
  const empty = !data || data.every((d) => d.income === 0 && d.expense === 0);

  return (
    <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
      <h3 className="text-sm font-semibold mb-3">Andamento ultimi 12 mesi</h3>
      <div className="h-64">
        {empty ? (
          <div className="h-full flex items-center justify-center text-sm text-slate-400">
            Aggiungi qualche transazione per vedere l'andamento.
          </div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" />
              <XAxis dataKey="label" stroke="#94a3b8" fontSize={12} />
              <YAxis stroke="#94a3b8" fontSize={12} width={64} />
              <Tooltip
                formatter={(v: number) => formatCurrency(v)}
                contentStyle={{
                  background: '#0f172a',
                  border: '1px solid #1e293b',
                  borderRadius: 8,
                }}
              />
              <Legend wrapperStyle={{ fontSize: 12 }} />
              <Line type="monotone" dataKey="income" name="Entrate" stroke="#10b981" strokeWidth={2} dot={false} />
              <Line type="monotone" dataKey="expense" name="Uscite" stroke="#f43f5e" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
}
