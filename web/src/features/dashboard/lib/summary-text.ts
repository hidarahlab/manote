import type { AppFeatureKey } from "@/lib/app-features";
import type { DashboardSummary } from "../api/dashboard-api";

export function summaryText(
  feature: AppFeatureKey,
  summary: DashboardSummary,
): string {
  switch (feature) {
    case "notes": {
      const { total, latestTitle } = summary.notes;
      if (total === 0) return "Belum ada catatan";
      return latestTitle
        ? `${total} catatan · terakhir: ${latestTitle}`
        : `${total} catatan`;
    }
    case "kanban": {
      const { todo, inProgress, done } = summary.kanban;
      if (todo + inProgress + done === 0) return "Belum ada kartu";
      return `${todo} belum · ${inProgress} dikerjakan · ${done} selesai`;
    }
    case "tasks": {
      const { pending, nextTitle } = summary.tasks;
      if (pending === 0) return "Belum ada tugas";
      return nextTitle
        ? `${pending} tugas · berikutnya: ${nextTitle}`
        : `${pending} tugas`;
    }
  }
}

export function greeting(date: Date = new Date()): string {
  const hour = date.getHours();
  if (hour >= 4 && hour < 11) return "Selamat pagi";
  if (hour >= 11 && hour < 15) return "Selamat siang";
  if (hour >= 15 && hour < 18) return "Selamat sore";
  return "Selamat malam";
}

export function initials(fullName: string): string {
  return fullName
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((word) => word[0])
    .join("")
    .toUpperCase();
}
