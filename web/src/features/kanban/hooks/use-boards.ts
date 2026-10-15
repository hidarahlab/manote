import { useQuery, useQueryClient } from "@tanstack/react-query";
import { getBoard, getBoards } from "../api/kanban-api";

export const boardsQueryKey = ["boards"] as const;
export const boardQueryKey = (id: number) => ["boards", "detail", id] as const;

export function useBoards() {
  return useQuery({ queryKey: [...boardsQueryKey, "list"], queryFn: getBoards });
}

export function useBoard(id: number) {
  return useQuery({ queryKey: boardQueryKey(id), queryFn: () => getBoard(id) });
}

// Setelah isi kerjaan berubah: segarkan daftar, papan, dan ringkasan dashboard.
export function useRefreshKanban() {
  const queryClient = useQueryClient();
  return () =>
    Promise.all([
      queryClient.invalidateQueries({ queryKey: boardsQueryKey }),
      queryClient.invalidateQueries({ queryKey: ["dashboard"] }),
    ]);
}
