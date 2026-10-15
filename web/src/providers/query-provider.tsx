"use client";

import {
  MutationCache,
  QueryCache,
  QueryClient,
  QueryClientProvider,
} from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { ApiError } from "@/lib/api-client";
import { ApiCode } from "@/lib/api-codes";

function createQueryClient(onSessionExpired: () => void) {
  // Sesi berakhir di tengah pemakaian: kembali ke login dari halaman mana pun.
  function handleError(error: unknown) {
    if (error instanceof ApiError && error.code === ApiCode.TOKEN_INVALID) {
      onSessionExpired();
    }
  }

  return new QueryClient({
    queryCache: new QueryCache({ onError: handleError }),
    mutationCache: new MutationCache({ onError: handleError }),
    defaultOptions: {
      queries: {
        // Data dimuat sekali saat halaman pertama dibuka, lalu hanya diperbarui lewat tombol
        // "Sinkronkan" atau setelah pengguna sendiri mengubah datanya. Tidak ada muat ulang
        // otomatis saat kembali ke tab atau halaman.
        staleTime: Infinity,
        refetchOnWindowFocus: false,
        refetchOnReconnect: false,
        // Ulangi hanya jika server tidak terjangkau; error dari server tidak akan berubah.
        retry: (failureCount, error) =>
          error instanceof ApiError && error.isUnreachable && failureCount < 2,
      },
    },
  });
}

export function QueryProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [queryClient] = useState(() =>
    createQueryClient(() => router.replace("/login?reason=expired")),
  );

  return (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
}
