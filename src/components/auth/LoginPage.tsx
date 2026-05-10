import { GoogleLogin } from '@react-oauth/google';
import { LineChart, ShieldAlert } from 'lucide-react';
import { useState } from 'react';
import { useAuthStore } from '@/store/useAuthStore';

export function LoginPage() {
  const setToken = useAuthStore((s) => s.setToken);
  const [error, setError] = useState<string | null>(null);

  return (
    <div className="min-h-dvh flex items-center justify-center bg-slate-950 text-slate-100 p-6">
      <div className="w-full max-w-sm rounded-2xl border border-slate-800 bg-slate-900/60 p-8 shadow-xl">
        <div className="flex items-center gap-3 mb-6">
          <div className="size-10 rounded-xl bg-brand-600/20 flex items-center justify-center">
            <LineChart className="size-5 text-brand-500" />
          </div>
          <div>
            <h1 className="text-lg font-semibold leading-tight">Budget Website</h1>
            <p className="text-xs text-slate-400">Accesso personale</p>
          </div>
        </div>

        <p className="text-sm text-slate-300 mb-6">
          Accedi con il tuo account Google per usare l'app. L'accesso è
          limitato a un singolo utente autorizzato.
        </p>

        <div className="flex justify-center">
          <GoogleLogin
            onSuccess={(cred) => {
              setError(null);
              if (cred.credential) {
                setToken(cred.credential);
              } else {
                setError('Credenziale mancante dalla risposta di Google.');
              }
            }}
            onError={() => setError('Login Google fallito. Riprova.')}
            useOneTap={false}
            theme="filled_black"
            shape="pill"
            text="signin_with"
          />
        </div>

        {error && (
          <div className="mt-4 flex items-start gap-2 rounded-lg border border-red-900/60 bg-red-950/40 p-3 text-sm text-red-200">
            <ShieldAlert className="size-4 mt-0.5 shrink-0" />
            <span>{error}</span>
          </div>
        )}
      </div>
    </div>
  );
}
