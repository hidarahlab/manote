import { apiFetch } from "@/lib/api-client";

// Satu tugas: nama dan kapan harus mulai. Alarm berbunyi pada waktu mulainya.
export type TaskItem = {
  id: number;
  // ID yang sama dipakai aplikasi iOS untuk tugas ini.
  clientId: string;
  title: string;
  // Keterangan tambahan, misalnya isi catatan asal tugas ini.
  description: string;
  startAt: string;
  done: boolean;
  doneAt: string | null;
  createdAt: string;
  updatedAt: string;
};

export type TaskDraft = {
  title: string;
  // Tidak dikirim saat mengubah berarti keterangan lama dipertahankan.
  description?: string;
  startAt: string;
  done?: boolean;
  // Hanya saat membuat: catatan yang dipindahkan menjadi tugas ini, lalu dihapus oleh server.
  noteClientId?: string;
};

// Daftar menampilkan error-nya sendiri di halaman; aksi lainnya memakai toast.
export function getTasks() {
  return apiFetch<TaskItem[]>("/api/tasks", undefined, { handlesError: true });
}

export function createTask(draft: TaskDraft) {
  return apiFetch<TaskItem>("/api/tasks", {
    method: "POST",
    body: JSON.stringify(draft),
  });
}

export function updateTask(id: number, draft: TaskDraft) {
  return apiFetch<TaskItem>(`/api/tasks/${id}`, {
    method: "PUT",
    body: JSON.stringify(draft),
  });
}

export function deleteTask(id: number) {
  return apiFetch<void>(`/api/tasks/${id}`, { method: "DELETE" });
}
