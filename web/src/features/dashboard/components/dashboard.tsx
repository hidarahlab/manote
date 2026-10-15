"use client";

import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useState } from "react";
import { AuthPending } from "@/components/auth-pending";
import { ChevronRightIcon } from "@/components/icons";
import { SyncBar } from "@/components/sync-bar";
import { useRequireUser } from "@/features/auth/hooks/use-require-user";
import { boardsQueryKey } from "@/features/kanban/hooks/use-boards";
import { notesQueryKey } from "@/features/notes/hooks/use-notes";
import { tasksQueryKey } from "@/features/tasks/hooks/use-tasks";
import { appFeatures, type AppFeatureKey } from "@/lib/app-features";
import { useDashboardSummary } from "../hooks/use-dashboard-summary";
import { greeting, summaryText } from "../lib/summary-text";

export function Dashboard() {
  const { user, errorMessage, retry } = useRequireUser();
  const summary = useDashboardSummary();
  const queryClient = useQueryClient();
  const [isSyncingAll, setIsSyncingAll] = useState(false);
  const [syncFailed, setSyncFailed] = useState(false);
  const [syncedAllAt, setSyncedAllAt] = useState(0);

  // Sinkron seluruh data aplikasi: catatan, tugas, semua kerjaan beserta papannya, dan ringkasan.
  // Halaman Catatan dan Kerjaan hanya menyinkronkan datanya masing-masing.
  async function syncAll() {
    setIsSyncingAll(true);
    const keys = [notesQueryKey, tasksQueryKey, boardsQueryKey, ["dashboard"]];
    await Promise.all(
      keys.map((queryKey) => queryClient.refetchQueries({ queryKey, type: "all" })),
    );
    const failed = keys.some((queryKey) =>
      queryClient
        .getQueryCache()
        .findAll({ queryKey })
        .some((query) => query.state.status === "error"),
    );
    setSyncFailed(failed);
    if (!failed) setSyncedAllAt(Date.now());
    setIsSyncingAll(false);
  }

  if (!user) {
    return <AuthPending errorMessage={errorMessage} onRetry={retry} />;
  }

  function summaryFor(feature: AppFeatureKey) {
    if (summary.isPending) return "Memuat...";
    if (summary.isError) return "Ringkasan tidak tersedia";
    return summaryText(feature, summary.data);
  }

  return (
    <div className="flex w-full flex-1 flex-col gap-5 p-6 lg:p-8">
      <header>
        <p className="text-sm text-muted" suppressHydrationWarning>
          {greeting()}
        </p>
        <h1 className="truncate text-2xl font-semibold">{user.fullName}</h1>
      </header>

      <SyncBar
        isSyncing={isSyncingAll || summary.isFetching}
        isError={syncFailed || summary.isError}
        lastSyncedAt={syncedAllAt || summary.dataUpdatedAt}
        onSync={() => void syncAll()}
      />

      <ul className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
        {appFeatures.map((feature) => (
          <li key={feature.key}>
            <Link
              href={feature.href}
              className={`flex min-h-21 items-center gap-4 rounded-[20px] p-4 ${feature.backgroundClass}`}
            >
              <feature.Icon
                width={26}
                height={26}
                className={feature.titleClass}
              />
              <div className="min-w-0 flex-1">
                <h2 className={`font-semibold ${feature.titleClass}`}>
                  {feature.title}
                </h2>
                <p className={`truncate text-sm ${feature.subtitleClass}`}>
                  {summaryFor(feature.key)}
                </p>
              </div>
              <ChevronRightIcon
                width={16}
                height={16}
                className={feature.subtitleClass}
              />
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
