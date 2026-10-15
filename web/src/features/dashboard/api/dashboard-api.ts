import { apiFetch } from "@/lib/api-client";

export type DashboardSummary = {
  notes: { total: number; latestTitle: string | null };
  kanban: { todo: number; inProgress: number; done: number };
  tasks: { pending: number; nextTitle: string | null; nextStartAt: string | null };
};

export function getDashboardSummary() {
  return apiFetch<DashboardSummary>("/api/dashboard/summary", undefined, {
    handlesError: true,
  });
}
