import { useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { tokenStorage } from "../lib/token-storage";

export function useLogout() {
  const queryClient = useQueryClient();
  const router = useRouter();

  return () => {
    tokenStorage.clear();
    queryClient.clear();
    router.replace("/login");
  };
}
