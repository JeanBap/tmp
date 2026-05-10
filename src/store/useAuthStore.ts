import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { jwtDecode } from 'jwt-decode';

interface GoogleIdTokenPayload {
  email: string;
  email_verified?: boolean;
  name?: string;
  picture?: string;
  exp: number; // seconds
  sub: string;
}

export interface AuthUser {
  email: string;
  name?: string;
  picture?: string;
  sub: string;
}

interface AuthState {
  idToken: string | null;
  user: AuthUser | null;
  expiresAt: number | null; // epoch ms

  setToken: (token: string) => void;
  signOut: () => void;
  isAuthenticated: () => boolean;
  isAllowed: () => boolean;
}

const ALLOWED_EMAIL = (import.meta.env.VITE_ALLOWED_EMAIL ?? '').toLowerCase();

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      idToken: null,
      user: null,
      expiresAt: null,

      setToken: (token: string) => {
        try {
          const payload = jwtDecode<GoogleIdTokenPayload>(token);
          set({
            idToken: token,
            expiresAt: payload.exp * 1000,
            user: {
              email: payload.email,
              name: payload.name,
              picture: payload.picture,
              sub: payload.sub,
            },
          });
        } catch {
          set({ idToken: null, user: null, expiresAt: null });
        }
      },

      signOut: () => set({ idToken: null, user: null, expiresAt: null }),

      isAuthenticated: () => {
        const { idToken, expiresAt } = get();
        return !!idToken && !!expiresAt && expiresAt > Date.now();
      },

      isAllowed: () => {
        const email = get().user?.email?.toLowerCase();
        return !!email && (!ALLOWED_EMAIL || email === ALLOWED_EMAIL);
      },
    }),
    {
      name: 'budget-auth',
      storage: createJSONStorage(() => localStorage),
      partialize: (s) => ({ idToken: s.idToken, user: s.user, expiresAt: s.expiresAt }),
    },
  ),
);
