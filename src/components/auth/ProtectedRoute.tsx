import { useEffect, type ReactNode } from 'react';
import { useAuthStore } from '@/store/useAuthStore';
import { cloudSync } from '@/db/cloudSync';
import { LoginPage } from './LoginPage';
import { AccessDenied } from './AccessDenied';

interface Props {
  children: ReactNode;
}

export function ProtectedRoute({ children }: Props) {
  const { idToken, expiresAt, isAuthenticated, isAllowed, signOut } = useAuthStore();
  const authed = isAuthenticated();
  const allowed = isAllowed();

  // Auto sign-out when the cached Google ID token expires.
  useEffect(() => {
    if (!idToken || !expiresAt) return;
    const ms = expiresAt - Date.now();
    if (ms <= 0) {
      signOut();
      return;
    }
    const timer = setTimeout(() => signOut(), ms);
    return () => clearTimeout(timer);
  }, [idToken, expiresAt, signOut]);

  // Start cloud sync only when fully authorised; stop when user signs out.
  useEffect(() => {
    if (authed && allowed) {
      cloudSync.start();
      return () => cloudSync.stop();
    }
  }, [authed, allowed]);

  if (!authed) return <LoginPage />;
  if (!allowed) return <AccessDenied />;
  return <>{children}</>;
}
