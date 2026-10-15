"use client";

import { useEffect, useState } from "react";
import { AuthPending } from "@/components/auth-pending";
import { MoonIcon, SunIcon } from "@/components/icons";
import { useRequireUser } from "@/features/auth/hooks/use-require-user";
import { currentTheme, setTheme, type Theme } from "@/lib/theme";

const themes = [
  { value: "light", label: "Terang", Icon: SunIcon },
  { value: "dark", label: "Gelap", Icon: MoonIcon },
] as const;

export function SettingsView() {
  const { user, errorMessage, retry } = useRequireUser();
  // Tema hanya bisa dibaca di browser, setelah halaman tampil; null berarti belum dibaca.
  const [theme, setCurrent] = useState<Theme | null>(null);

  useEffect(() => {
    const initial = setTimeout(() => setCurrent(currentTheme()), 0);
    return () => clearTimeout(initial);
  }, []);

  if (!user) {
    return <AuthPending errorMessage={errorMessage} onRetry={retry} />;
  }

  function choose(next: Theme) {
    setTheme(next);
    setCurrent(next);
  }

  return (
    <div className="flex w-full flex-1 flex-col gap-6 p-6 lg:p-8">
      <h1 className="text-2xl font-semibold">Pengaturan</h1>

      <section
        aria-labelledby="theme-heading"
        className="flex max-w-xl flex-col gap-4 rounded-[20px] bg-surface p-5"
      >
        <div>
          <h2 id="theme-heading" className="font-semibold">
            Tema
          </h2>
          <p className="mt-1 text-sm text-muted">
            Berlaku di browser ini. Sebelum dipilih, tema mengikuti perangkat.
          </p>
        </div>

        <div role="radiogroup" aria-labelledby="theme-heading" className="flex gap-3">
          {themes.map(({ value, label, Icon }) => {
            const isSelected = theme === value;
            return (
              <button
                key={value}
                role="radio"
                aria-checked={isSelected}
                onClick={() => choose(value)}
                className={`flex flex-1 items-center justify-center gap-2 rounded-[14px] px-4 py-3 text-sm font-medium outline-offset-2 focus-visible:outline-2 focus-visible:outline-primary ${
                  isSelected
                    ? "bg-primary text-on-primary"
                    : "bg-background text-muted hover:text-foreground"
                }`}
              >
                <Icon width={18} height={18} />
                {label}
              </button>
            );
          })}
        </div>
      </section>
    </div>
  );
}
