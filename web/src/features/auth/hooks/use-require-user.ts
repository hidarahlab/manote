import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { ApiError } from "@/lib/api-client";
import { ApiCode } from "@/lib/api-codes";
import { useCurrentUser } from "./use-current-user";

// Untuk halaman yang butuh login. Sesi tidak valid mengalihkan ke /login; error lain
// (misalnya server tidak terjangkau) dikembalikan supaya halaman bisa menampilkannya.
export function useRequireUser() {
  const router = useRouter();
  const query = useCurrentUser();
  const error = query.error instanceof ApiError ? query.error : null;
  const isUnauthorized = error?.isUnauthorized ?? false;
  const isExpired = error?.code === ApiCode.TOKEN_INVALID;

  useEffect(() => {
    if (isUnauthorized) {
      router.replace(isExpired ? "/login?reason=expired" : "/login");
    }
  }, [isUnauthorized, isExpired, router]);

  return {
    user: query.data,
    errorMessage: query.isError && !isUnauthorized ? query.error.message : null,
    retry: () => void query.refetch(),
  };
}
