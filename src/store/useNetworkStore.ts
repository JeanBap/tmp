import { useEffect } from 'react';
import { create } from 'zustand';

type SyncState = 'idle' | 'syncing' | 'error';

interface NetworkState {
  online: boolean;
  syncState: SyncState;
  lastSyncAt: number | null;
  pendingCount: number;
  setOnline: (v: boolean) => void;
  setSyncState: (s: SyncState) => void;
  setLastSyncAt: (t: number) => void;
  setPendingCount: (n: number) => void;
}

export const useNetworkStore = create<NetworkState>((set) => ({
  online: typeof navigator !== 'undefined' ? navigator.onLine : true,
  syncState: 'idle',
  lastSyncAt: null,
  pendingCount: 0,
  setOnline: (online) => set({ online }),
  setSyncState: (syncState) => set({ syncState }),
  setLastSyncAt: (lastSyncAt) => set({ lastSyncAt }),
  setPendingCount: (pendingCount) => set({ pendingCount }),
}));

/** Hook to register listeners once at app root. */
export function useNetworkListeners() {
  const setOnline = useNetworkStore((s) => s.setOnline);
  useEffect(() => {
    const goOnline = () => setOnline(true);
    const goOffline = () => setOnline(false);
    window.addEventListener('online', goOnline);
    window.addEventListener('offline', goOffline);
    return () => {
      window.removeEventListener('online', goOnline);
      window.removeEventListener('offline', goOffline);
    };
  }, [setOnline]);
}
