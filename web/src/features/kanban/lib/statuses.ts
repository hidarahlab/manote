import type { CardStatus } from "../api/kanban-api";

// Kolom papan kanban, urut dari kiri ke kanan.
export const cardStatuses: { status: CardStatus; label: string }[] = [
  { status: "BACKLOG", label: "Backlog" },
  { status: "TODO", label: "Todo" },
  { status: "IN_PROGRESS", label: "In Progress" },
  { status: "REVIEW", label: "Review" },
  { status: "DONE", label: "Done" },
];

export function statusLabel(status: CardStatus): string {
  return cardStatuses.find((item) => item.status === status)?.label ?? status;
}
