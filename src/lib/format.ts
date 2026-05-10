const eur = new Intl.NumberFormat('it-IT', {
  style: 'currency',
  currency: 'EUR',
  maximumFractionDigits: 2,
});

const dateFmt = new Intl.DateTimeFormat('it-IT', { dateStyle: 'medium' });
const monthFmt = new Intl.DateTimeFormat('it-IT', { month: 'long', year: 'numeric' });

export function formatCurrency(amount: number, currency = 'EUR'): string {
  if (currency === 'EUR') return eur.format(amount);
  return new Intl.NumberFormat('it-IT', { style: 'currency', currency }).format(amount);
}

export function formatDate(iso: string): string {
  return dateFmt.format(new Date(iso));
}

export function formatMonth(monthCursor: string): string {
  const [y, m] = monthCursor.split('-').map(Number);
  return monthFmt.format(new Date(y, m - 1, 1));
}

export function formatPercent(n: number): string {
  return `${(n * 100).toFixed(1)}%`;
}
