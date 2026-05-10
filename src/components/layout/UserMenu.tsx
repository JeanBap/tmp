import { LogOut, User as UserIcon } from 'lucide-react';
import { useAuthStore } from '@/store/useAuthStore';

export function UserMenu({ compact = false }: { compact?: boolean }) {
  const { user, signOut } = useAuthStore();
  if (!user) return null;

  return (
    <div
      className={`flex items-center gap-3 ${
        compact ? 'px-2 py-2' : 'px-3 py-3 border-t border-slate-800'
      }`}
    >
      {user.picture ? (
        <img
          src={user.picture}
          alt=""
          referrerPolicy="no-referrer"
          className="size-8 rounded-full"
        />
      ) : (
        <div className="size-8 rounded-full bg-slate-700 flex items-center justify-center">
          <UserIcon className="size-4" />
        </div>
      )}
      <div className="flex-1 min-w-0">
        <div className="text-sm font-medium truncate">{user.name ?? user.email}</div>
        <div className="text-xs text-slate-400 truncate">{user.email}</div>
      </div>
      <button
        type="button"
        onClick={signOut}
        title="Esci"
        className="rounded-md p-2 text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
      >
        <LogOut className="size-4" />
      </button>
    </div>
  );
}
