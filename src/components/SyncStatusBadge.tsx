import { Cloud, CloudOff, Loader2, AlertTriangle } from 'lucide-react';
import { useNetworkStore } from '@/store/useNetworkStore';
import { formatDistanceToNow } from 'date-fns';
import { it } from 'date-fns/locale';

export function SyncStatusBadge() {
  const { online, syncState, lastSyncAt, pendingCount } = useNetworkStore();

  let Icon = Cloud;
  let tone = 'text-emerald-400';
  let label: string;

  if (!online) {
    Icon = CloudOff;
    tone = 'text-slate-400';
    label = pendingCount > 0 ? `Offline · ${pendingCount} in attesa` : 'Offline';
  } else if (syncState === 'syncing') {
    Icon = Loader2;
    tone = 'text-sky-400 animate-spin';
    label = 'Sincronizzazione…';
  } else if (syncState === 'error') {
    Icon = AlertTriangle;
    tone = 'text-amber-400';
    label = pendingCount > 0 ? `Errore · ${pendingCount} in attesa` : 'Errore di sync';
  } else if (pendingCount > 0) {
    Icon = Cloud;
    tone = 'text-amber-400';
    label = `${pendingCount} in attesa`;
  } else if (lastSyncAt) {
    label = `Sincronizzato ${formatDistanceToNow(lastSyncAt, { addSuffix: true, locale: it })}`;
  } else {
    label = 'In attesa di sync';
  }

  return (
    <div className="flex items-center gap-2 px-3 py-2 mx-2 rounded-md bg-slate-900/70 border border-slate-800 text-xs">
      <Icon className={`size-4 shrink-0 ${tone}`} />
      <span className="truncate text-slate-300">{label}</span>
    </div>
  );
}
