import { useQuery } from "@tanstack/react-query";
import { getNote, getNotes } from "../api/notes-api";

export const notesQueryKey = ["notes"] as const;
export const noteDetailQueryKey = (id: number) =>
  ["notes", "detail", id] as const;

export function useNotes() {
  return useQuery({ queryKey: [...notesQueryKey, "list"], queryFn: getNotes });
}

// Dipakai sebagai nilai awal editor, jadi tidak boleh berubah saat sedang mengetik.
export function useNote(id: number) {
  return useQuery({
    queryKey: noteDetailQueryKey(id),
    queryFn: () => getNote(id),
    refetchOnWindowFocus: false,
    refetchOnReconnect: false,
    staleTime: Infinity,
    gcTime: 0,
  });
}
