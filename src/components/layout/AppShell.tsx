import { NavLink, Outlet } from 'react-router-dom';
import { LayoutDashboard, Receipt, LineChart, Settings } from 'lucide-react';
import type { ComponentType } from 'react';
import { UserMenu } from './UserMenu';

type NavItem = { to: string; label: string; icon: ComponentType<{ className?: string }> };

const NAV: NavItem[] = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/transactions', label: 'Transazioni', icon: Receipt },
  { to: '/investments', label: 'Investimenti', icon: LineChart },
  { to: '/settings', label: 'Impostazioni', icon: Settings },
];

export function AppShell() {
  return (
    <div className="min-h-dvh flex bg-slate-950 text-slate-100">
      {/* Sidebar (desktop) */}
      <aside className="hidden md:flex w-60 shrink-0 flex-col border-r border-slate-800 pt-safe">
        <div className="px-5 py-4 text-lg font-semibold tracking-tight">Budget</div>
        <nav className="flex-1 px-2 space-y-1">
          {NAV.map(({ to, label, icon: Icon }) => (
            <NavLink
              key={to}
              to={to}
              end={to === '/'}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2 rounded-md text-sm transition-colors ${
                  isActive
                    ? 'bg-slate-800 text-white'
                    : 'text-slate-300 hover:bg-slate-800/60 hover:text-white'
                }`
              }
            >
              <Icon className="size-5" />
              {label}
            </NavLink>
          ))}
        </nav>
        <UserMenu />
      </aside>

      <div className="flex-1 flex flex-col min-w-0">
        <main className="flex-1 overflow-y-auto pb-24 md:pb-6 pt-safe">
          <div className="mx-auto max-w-5xl p-4 md:p-6">
            <Outlet />
          </div>
        </main>

        {/* Bottom nav (mobile) */}
        <nav className="md:hidden fixed bottom-0 inset-x-0 border-t border-slate-800 bg-slate-950/95 backdrop-blur pb-safe">
          <div className="grid grid-cols-4">
            {NAV.map(({ to, label, icon: Icon }) => (
              <NavLink
                key={to}
                to={to}
                end={to === '/'}
                className={({ isActive }) =>
                  `flex flex-col items-center gap-0.5 py-2 text-xs ${
                    isActive ? 'text-brand-500' : 'text-slate-400'
                  }`
                }
              >
                <Icon className="size-5" />
                {label}
              </NavLink>
            ))}
          </div>
        </nav>
      </div>
    </div>
  );
}
