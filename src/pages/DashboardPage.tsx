import { MonthSwitcher } from '@/components/dashboard/MonthSwitcher';
import { SummaryCards } from '@/components/dashboard/SummaryCards';
import { CategoryDoughnut } from '@/components/dashboard/CategoryDoughnut';
import { MonthlyTrendChart } from '@/components/dashboard/MonthlyTrendChart';

export function DashboardPage() {
  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <h1 className="text-2xl font-semibold">Dashboard</h1>
        <MonthSwitcher />
      </div>
      <SummaryCards />
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <CategoryDoughnut />
        <MonthlyTrendChart />
      </div>
    </div>
  );
}
