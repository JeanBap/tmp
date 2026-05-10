import { useEffect, type ReactNode } from 'react';
import { useAuthStore } from '@/store/useAuthStore';
import { LoginPage } from './LoginPage';
import { AccessDenied } from './AccessDenied';

interface Props {
  children: ReactNode;
}

export function ProtectedRoute({ children }: Props) {
  const { idToken, expiresAt, isAuthenticated, isAllowed, signOut } = useAuthStore();

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

  if (!isAuthenticated()) return <LoginPage />;
  if (!isAllowed()) return <AccessDenied />;
  return <>{children}</>;
}
