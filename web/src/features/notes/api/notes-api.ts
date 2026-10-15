import { apiFetch } from "@/lib/api-client";

export type Note = {
  id: number;
  // ID yang sama dipakai aplikasi iOS untuk catatan ini.
  clientId: string;
  title: string;
  content: string;
  createdAt: string;
  updatedAt: string;
  reminderAt: string | null;
};

export type NoteDraft = {
  title: string;
  content: string;
};

// Daftar dan detail menampilkan error-nya sendiri di halaman.
export function getNotes() {
  return apiFetch<Note[]>("/api/notes", undefined, { handlesError: true });
}

export function getNote(id: number) {
  return apiFetch<Note>(`/api/notes/${id}`, undefined, { handlesError: true });
}

// Simpan otomatis berjalan di latar belakang; gagalnya tampil di indikator simpan editor.
export function createNote(draft: NoteDraft) {
  return apiFetch<Note>(
    "/api/notes",
    { method: "POST", body: JSON.stringify(draft) },
    { handlesError: true },
  );
}

export function updateNote(id: number, draft: NoteDraft) {
  return apiFetch<Note>(
    `/api/notes/${id}`,
    { method: "PUT", body: JSON.stringify(draft) },
    { handlesError: true },
  );
}

// `silent` untuk membuang catatan kosong di latar belakang, tanpa toast jika gagal.
export function deleteNote(id: number, { silent = false } = {}) {
  return apiFetch<void>(
    `/api/notes/${id}`,
    { method: "DELETE" },
    { handlesError: silent },
  );
}
