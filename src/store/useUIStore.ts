import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

type Theme = 'dark' | 'light';

interface UIState {
  theme: Theme;
  monthCursor: string; // yyyy-MM, current month in dashboard
  setTheme: (t: Theme) => void;
  setMonthCursor: (m: string) => void;
}

const currentMonth = () => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
};

export const useUIStore = create<UIState>()(
  persist(
    (set) => ({
      theme: 'dark',
      monthCursor: currentMonth(),
      setTheme: (theme) => set({ theme }),
      setMonthCursor: (monthCursor) => set({ monthCursor }),
    }),
    {
      name: 'budget-ui',
      storage: createJSONStorage(() => localStorage),
    },
  ),
);
