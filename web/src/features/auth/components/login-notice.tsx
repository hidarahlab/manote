"use client";

import { useSearchParams } from "next/navigation";

// Pesan di atas form login setelah dialihkan dari halaman lain.
export function LoginNotice() {
  const reason = useSearchParams().get("reason");
  if (reason !== "expired") return null;

  return (
    <p className="rounded-[14px] bg-primary-soft px-4 py-3 text-sm text-on-primary-soft">
      Sesi berakhir. Silakan login lagi.
    </p>
  );
}
