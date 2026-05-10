import { useEffect } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { AppShell } from './components/layout/AppShell';
import { DashboardPage } from './pages/DashboardPage';
import { TransactionsPage } from './pages/TransactionsPage';
import { InvestmentsPage } from './pages/InvestmentsPage';
import { SettingsPage } from './pages/SettingsPage';
import { seedDefaults } from './db/database';
import { useNetworkListeners } from './store/useNetworkStore';

export default function App() {
  useNetworkListeners();
  useEffect(() => {
    seedDefaults().catch((err) => console.error('seed failed', err));
  }, []);

  return (
    <Routes>
      <Route element={<AppShell />}>
        <Route index element={<DashboardPage />} />
        <Route path="transactions" element={<TransactionsPage />} />
        <Route path="investments" element={<InvestmentsPage />} />
        <Route path="settings" element={<SettingsPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
