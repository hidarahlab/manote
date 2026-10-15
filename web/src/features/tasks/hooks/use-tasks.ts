import { useQuery, useQueryClient } from "@tanstack/react-query";
import { getTasks } from "../api/tasks-api";

export const tasksQueryKey = ["tasks"] as const;

export function useTasks() {
  return useQuery({ queryKey: [...tasksQueryKey, "list"], queryFn: getTasks });
}

// Setelah tugas berubah: segarkan daftar tugas dan ringkasan dashboard.
export function useRefreshTasks() {
  const queryClient = useQueryClient();
  return () =>
    Promise.all([
      queryClient.invalidateQueries({ queryKey: tasksQueryKey }),
      queryClient.invalidateQueries({ queryKey: ["dashboard"] }),
    ]);
}
