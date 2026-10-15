import { AppShell } from "@/components/app-shell";

// Semua halaman setelah login memakai kerangka yang sama: menu di samping, isi memenuhi layar.
export default function AppLayout({ children }: { children: React.ReactNode }) {
  return <AppShell>{children}</AppShell>;
}
