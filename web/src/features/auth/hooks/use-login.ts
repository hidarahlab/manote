import { useMutation, useQueryClient } from "@tanstack/react-query";
import { login } from "../api/auth-api";
import { tokenStorage } from "../lib/token-storage";
import { currentUserQueryKey } from "./use-current-user";

export function useLogin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: login,
    onSuccess: (response) => {
      tokenStorage.set(response.accessToken);
      queryClient.setQueryData(currentUserQueryKey, response.user);
    },
  });
}
