"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Suspense } from "react";
import { HomeIcon, LogoutIcon, SettingsIcon } from "@/components/icons";
import { LogoMark } from "@/components/logo-mark";
import { useCurrentUser } from "@/features/auth/hooks/use-current-user";
import { useLogout } from "@/features/auth/hooks/use-logout";
import { initials } from "@/features/dashboard/lib/summary-text";
import { TaskAlarm } from "@/features/tasks/components/task-alarm";
import { appFeatures } from "@/lib/app-features";

const navItems = [
  { title: "Dashboard", href: "/dashboard", Icon: HomeIcon },
  ...appFeatures.map(({ title, href, Icon }) => ({ title, href, Icon })),
  { title: "Pengaturan", href: "/settings", Icon: SettingsIcon },
];

// Kerangka halaman setelah login. Layar lebar: menu di sisi kiri dan isi memenuhi sisa layar.
// Layar sempit: menu menjadi baris di atas.
export function AppShell({ children }: { children: React.ReactNode }) {
  const logout = useLogout();
  const { data: user } = useCurrentUser();

  return (
    <div className="flex min-h-dvh w-full flex-1 flex-col md:flex-row">
      <aside className="flex shrink-0 items-center gap-2 border-b border-surface px-4 py-3 md:sticky md:top-0 md:h-dvh md:w-60 md:flex-col md:items-stretch md:gap-6 md:border-b-0 md:border-r md:p-5">
        <Link href="/dashboard" className="flex items-center gap-3">
          <LogoMark size={36} />
          <span className="hidden text-lg font-bold md:inline">Manote</span>
        </Link>

        {/* Halaman dengan ID di alamatnya baru tahu alamatnya saat dibuka, jadi menu aktif menyusul. */}
        <Suspense fallback={<Nav pathname={null} />}>
          <CurrentNav />
        </Suspense>

        <div className="flex items-center gap-3">
          {user && (
            <>
              <div className="hidden size-9 shrink-0 items-center justify-center rounded-full bg-primary-soft text-sm font-semibold text-on-primary-soft md:flex">
                {initials(user.fullName)}
              </div>
              <div className="hidden min-w-0 flex-1 md:block">
                <p className="truncate text-sm font-medium">{user.fullName}</p>
                <p className="truncate text-xs text-muted">{user.email}</p>
              </div>
            </>
          )}
          <button
            onClick={logout}
            aria-label="Keluar"
            title="Keluar"
            className="flex size-9 shrink-0 items-center justify-center rounded-full text-muted hover:bg-surface hover:text-danger"
          >
            <LogoutIcon width={18} height={18} />
          </button>
        </div>
      </aside>

      <main className="flex min-w-0 flex-1 flex-col">{children}</main>
      <TaskAlarm />
    </div>
  );
}

function CurrentNav() {
  return <Nav pathname={usePathname()} />;
}

function Nav({ pathname }: { pathname: string | null }) {
  return (
    <nav className="flex flex-1 items-center gap-1 md:flex-col md:items-stretch">
      {navItems.map(({ title, href, Icon }) => {
        const isActive =
          pathname !== null &&
          (pathname === href || pathname.startsWith(`${href}/`));
        return (
          <Link
            key={href}
            href={href}
            aria-current={isActive ? "page" : undefined}
            className={`flex items-center gap-3 rounded-[14px] px-3 py-2.5 text-sm font-medium ${
              isActive
                ? "bg-primary-soft text-on-primary-soft"
                : "text-muted hover:bg-surface hover:text-foreground"
            }`}
          >
            <Icon width={20} height={20} />
            <span className="hidden sm:inline">{title}</span>
          </Link>
        );
      })}
    </nav>
  );
}
