import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from 'recharts';
import { useCategoryBreakdown } from '@/db/queries';
import { useUIStore } from '@/store/useUIStore';
import { formatCurrency } from '@/lib/format';

export function CategoryDoughnut() {
  const monthCursor = useUIStore((s) => s.monthCursor);
  const data = useCategoryBreakdown(monthCursor, 'expense');
  const empty = !data || data.length === 0;

  return (
    <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
      <h3 className="text-sm font-semibold mb-3">Spese per categoria</h3>
      <div className="h-64">
        {empty ? (
          <div className="h-full flex items-center justify-center text-sm text-slate-400">
            Nessuna spesa nel periodo selezionato.
          </div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <PieChart>
              <Pie
                data={data}
                dataKey="total"
                nameKey="name"
                innerRadius="55%"
                outerRadius="85%"
                paddingAngle={2}
                stroke="#0f172a"
              >
                {data!.map((d) => (
                  <Cell key={d.category_id} fill={d.color} />
                ))}
              </Pie>
              <Tooltip
                formatter={(v: number) => formatCurrency(v)}
                contentStyle={{
                  background: '#0f172a',
                  border: '1px solid #1e293b',
                  borderRadius: 8,
                }}
              />
            </PieChart>
          </ResponsiveContainer>
        )}
      </div>
      {!empty && (
        <ul className="mt-3 space-y-1 text-sm">
          {data!.slice(0, 5).map((d) => (
            <li key={d.category_id} className="flex items-center justify-between">
              <span className="flex items-center gap-2 truncate">
                <span className="size-2.5 rounded-full" style={{ background: d.color }} />
                <span className="truncate">{d.name}</span>
              </span>
              <span className="tabular-nums text-slate-300">{formatCurrency(d.total)}</span>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
