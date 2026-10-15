import type { Card } from "../api/kanban-api";

export type DeadlineLevel = "none" | "safe" | "soon" | "urgent" | "overdue" | "done";

const DAY_MS = 24 * 60 * 60 * 1000;

// Warna kartu menurut sisa waktu ke tenggat:
// tanpa tenggat abu-abu, lebih dari 2 hari hijau muda, tinggal 2 hari kuning, tinggal 1 hari
// merah, sudah lewat tenggat hitam. Kartu di Done selalu hijau, apa pun tenggatnya.
export function deadlineLevel(card: Card, now: Date = new Date()): DeadlineLevel {
  if (card.status === "DONE") return "done";
  if (!card.deadlineAt) return "none";
  const remaining = new Date(card.deadlineAt).getTime() - now.getTime();
  if (remaining <= 0) return "overdue";
  if (remaining <= DAY_MS) return "urgent";
  if (remaining <= 2 * DAY_MS) return "soon";
  return "safe";
}

// Kelas ditulis utuh supaya terbaca oleh Tailwind.
export const deadlineClasses: Record<
  DeadlineLevel,
  { card: string; title: string; text: string }
> = {
  none: { card: "bg-background", title: "", text: "text-muted" },
  safe: { card: "bg-kanban-bg", title: "", text: "text-kanban-sub" },
  soon: { card: "bg-notes-bg", title: "", text: "text-notes-sub" },
  urgent: { card: "bg-urgent-bg", title: "", text: "text-urgent-sub" },
  overdue: { card: "bg-overdue-bg", title: "text-overdue-title", text: "text-overdue-sub" },
  done: { card: "bg-done-bg", title: "text-done-title", text: "text-done-sub" },
};

// Subjudul kartu di Done. Kartu yang belum punya waktu selesai memakai waktu ubah terakhirnya.
export function doneText(card: Card): string {
  return `Done date ${deadlineText(card.doneAt ?? card.updatedAt)}`;
}

export function deadlineText(iso: string): string {
  return new Intl.DateTimeFormat("id", {
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(iso));
}

// Nilai untuk <input type="datetime-local">, dalam waktu setempat.
export function toInputValue(iso: string | null): string {
  if (!iso) return "";
  const date = new Date(iso);
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60_000);
  return local.toISOString().slice(0, 16);
}

export function fromInputValue(value: string): string | null {
  return value === "" ? null : new Date(value).toISOString();
}
