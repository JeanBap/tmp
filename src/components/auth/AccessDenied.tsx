import { ShieldX, LogOut } from 'lucide-react';
import { useAuthStore } from '@/store/useAuthStore';

export function AccessDenied() {
  const { user, signOut } = useAuthStore();
  return (
    <div className="min-h-dvh flex items-center justify-center bg-slate-950 text-slate-100 p-6">
      <div className="w-full max-w-md rounded-2xl border border-red-900/60 bg-red-950/30 p-8 text-center">
        <div className="mx-auto size-12 rounded-full bg-red-900/40 flex items-center justify-center mb-4">
          <ShieldX className="size-6 text-red-300" />
        </div>
        <h1 className="text-lg font-semibold mb-2">Accesso negato</h1>
        <p className="text-sm text-slate-300 mb-6">
          L'account <span className="font-mono">{user?.email}</span> non è
          autorizzato ad accedere a questa applicazione.
        </p>
        <button
          type="button"
          onClick={signOut}
          className="inline-flex items-center gap-2 rounded-md bg-slate-800 hover:bg-slate-700 px-4 py-2 text-sm transition-colors"
        >
          <LogOut className="size-4" />
          Esci e cambia account
        </button>
      </div>
    </div>
  );
}
