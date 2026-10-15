"use client";

import { useSyncExternalStore } from "react";
import { dismissToast, getToast, subscribeToast } from "@/lib/toast";

// Tempat toast tampil; dipasang sekali di layout.
export function Toaster() {
  const toast = useSyncExternalStore(subscribeToast, getToast, () => null);
  if (!toast) return null;

  return (
    <div className="pointer-events-none fixed inset-x-0 top-4 z-50 flex justify-center px-4">
      <button
        key={toast.id}
        role={toast.kind === "error" ? "alert" : "status"}
        onClick={dismissToast}
        className={`pointer-events-auto w-full max-w-sm rounded-[14px] px-4 py-3 text-left text-sm text-white shadow-lg ${toast.kind === "error" ? "bg-[#a32d2d]" : "bg-[#0f6e56]"}`}
      >
        {toast.message}
      </button>
    </div>
  );
}
