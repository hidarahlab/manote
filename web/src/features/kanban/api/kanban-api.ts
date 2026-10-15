import { apiFetch } from "@/lib/api-client";

export type CardStatus = "BACKLOG" | "TODO" | "IN_PROGRESS" | "REVIEW" | "DONE";

export type Board = {
  id: number;
  name: string;
  totalCards: number;
  doneCards: number;
  createdAt: string;
  updatedAt: string;
};

export type Card = {
  id: number;
  boardId: number;
  title: string;
  description: string;
  status: CardStatus;
  position: number;
  // Catatan asal kartu ini, jika dibuat dari catatan (catatannya sudah dipindahkan).
  noteId: number | null;
  // Tenggat kartu; null berarti tidak ada tenggat.
  deadlineAt: string | null;
  // Kapan kartu masuk ke Done; null selama belum selesai.
  doneAt: string | null;
  createdAt: string;
  updatedAt: string;
};

export type BoardDetail = {
  id: number;
  name: string;
  cards: Card[];
};

export type NewCard = {
  title: string;
  description?: string;
  status?: CardStatus;
  // Catatan yang dipindahkan menjadi kartu ini: pengingatnya menjadi tenggat, lalu
  // catatannya dihapus oleh server.
  noteClientId?: string;
};

// Daftar dan papan menampilkan error-nya sendiri di halaman; aksi lainnya memakai toast.
export function getBoards() {
  return apiFetch<Board[]>("/api/boards", undefined, { handlesError: true });
}

export function getBoard(id: number) {
  return apiFetch<BoardDetail>(`/api/boards/${id}`, undefined, {
    handlesError: true,
  });
}

export function createBoard(name: string) {
  return apiFetch<Board>("/api/boards", {
    method: "POST",
    body: JSON.stringify({ name }),
  });
}

export function deleteBoard(id: number) {
  return apiFetch<void>(`/api/boards/${id}`, { method: "DELETE" });
}

export function createCard(boardId: number, card: NewCard) {
  return apiFetch<Card>(`/api/boards/${boardId}/cards`, {
    method: "POST",
    body: JSON.stringify(card),
  });
}

export function updateCard(
  id: number,
  card: { title: string; description: string; deadlineAt: string | null },
) {
  return apiFetch<Card>(`/api/cards/${id}`, {
    method: "PUT",
    body: JSON.stringify(card),
  });
}

export function moveCard(id: number, status: CardStatus, position: number) {
  return apiFetch<Card>(`/api/cards/${id}/move`, {
    method: "PUT",
    body: JSON.stringify({ status, position }),
  });
}

export function deleteCard(id: number) {
  return apiFetch<void>(`/api/cards/${id}`, { method: "DELETE" });
}
