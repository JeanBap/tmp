import { ChevronLeft, ChevronRight } from 'lucide-react';
import { useUIStore } from '@/store/useUIStore';
import { nextMonth, prevMonth } from '@/lib/dates';
import { formatMonth } from '@/lib/format';

export function MonthSwitcher() {
  const { monthCursor, setMonthCursor } = useUIStore();
  return (
    <div className="inline-flex items-center gap-1 rounded-full border border-slate-800 bg-slate-900/60 px-1 py-1">
      <button
        type="button"
        onClick={() => setMonthCursor(prevMonth(monthCursor))}
        className="rounded-full p-1.5 text-slate-300 hover:bg-slate-800"
        aria-label="Mese precedente"
      >
        <ChevronLeft className="size-4" />
      </button>
      <span className="px-3 text-sm font-medium capitalize tabular-nums">
        {formatMonth(monthCursor)}
      </span>
      <button
        type="button"
        onClick={() => setMonthCursor(nextMonth(monthCursor))}
        className="rounded-full p-1.5 text-slate-300 hover:bg-slate-800"
        aria-label="Mese successivo"
      >
        <ChevronRight className="size-4" />
      </button>
    </div>
  );
}
