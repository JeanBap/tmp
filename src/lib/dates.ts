import { addMonths as dfAddMonths, endOfMonth, format, parseISO, startOfMonth, subMonths } from 'date-fns';

export type MonthCursor = string; // 'yyyy-MM'

export function currentMonthCursor(): MonthCursor {
  return format(new Date(), 'yyyy-MM');
}

export function monthCursorToDate(c: MonthCursor): Date {
  return parseISO(`${c}-01`);
}

export function monthRange(c: MonthCursor): { start: string; end: string } {
  const d = monthCursorToDate(c);
  return {
    start: format(startOfMonth(d), 'yyyy-MM-dd'),
    end: format(endOfMonth(d), 'yyyy-MM-dd'),
  };
}

export function addMonths(c: MonthCursor, n: number): MonthCursor {
  return format(dfAddMonths(monthCursorToDate(c), n), 'yyyy-MM');
}

export function prevMonth(c: MonthCursor): MonthCursor {
  return addMonths(c, -1);
}
export function nextMonth(c: MonthCursor): MonthCursor {
  return addMonths(c, 1);
}

export function lastNMonths(n: number, anchor: MonthCursor = currentMonthCursor()): MonthCursor[] {
  const d = monthCursorToDate(anchor);
  const out: MonthCursor[] = [];
  for (let i = n - 1; i >= 0; i--) {
    out.push(format(subMonths(d, i), 'yyyy-MM'));
  }
  return out;
}
