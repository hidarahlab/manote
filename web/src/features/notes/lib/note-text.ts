import type { NoteDraft } from "../api/notes-api";

export function isBlank(draft: NoteDraft): boolean {
  return draft.title.trim() === "" && draft.content.trim() === "";
}

// Judul untuk ditampilkan: judul catatan, atau baris pertama isinya jika judul kosong.
export function displayTitle(draft: NoteDraft): string {
  if (draft.title.trim() !== "") return draft.title.trim();
  const firstLine = draft.content.trim().split("\n")[0] ?? "";
  return firstLine === "" ? "Tanpa judul" : firstLine;
}

export function preview(draft: NoteDraft): string {
  const lines = draft.content.trim().split("\n").filter(Boolean);
  const body = draft.title.trim() === "" ? lines.slice(1) : lines;
  return body.join(" ");
}

export function relativeTime(iso: string, now: Date = new Date()): string {
  const formatter = new Intl.RelativeTimeFormat("id", { numeric: "auto" });
  const minutes = Math.round((new Date(iso).getTime() - now.getTime()) / 60_000);
  if (Math.abs(minutes) < 1) return "baru saja";
  if (Math.abs(minutes) < 60) return formatter.format(minutes, "minute");
  const hours = Math.round(minutes / 60);
  if (Math.abs(hours) < 24) return formatter.format(hours, "hour");
  return formatter.format(Math.round(hours / 24), "day");
}
