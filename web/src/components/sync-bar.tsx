"use client";

// Baris status sinkron dengan tombol "Sinkronkan". Tiap halaman memakainya untuk datanya sendiri.
export function SyncBar({
  isSyncing,
  isError,
  lastSyncedAt,
  onSync,
}: {
  isSyncing: boolean;
  isError: boolean;
  // Waktu dalam milidetik; 0 berarti belum pernah.
  lastSyncedAt: number;
  onSync: () => void;
}) {
  const needsAttention = !isSyncing && isError;

  return (
    <div
      className={`flex items-center gap-2 rounded-[14px] bg-surface px-4 py-3 text-sm ${needsAttention ? "text-danger" : "text-muted"}`}
    >
      {isSyncing ? (
        <span className="size-4 animate-spin rounded-full border-2 border-primary-soft border-t-primary" />
      ) : (
        <span
          aria-hidden="true"
          className={`size-2 rounded-full ${needsAttention ? "bg-danger" : "bg-kanban-sub"}`}
        />
      )}
      <span className="min-w-0 flex-1 truncate" suppressHydrationWarning>
        {statusText({ isSyncing, isError, lastSyncedAt })}
      </span>
      <button
        onClick={onSync}
        disabled={isSyncing}
        className="font-semibold text-primary disabled:opacity-40"
      >
        Sinkronkan
      </button>
    </div>
  );
}

function statusText({
  isSyncing,
  isError,
  lastSyncedAt,
}: {
  isSyncing: boolean;
  isError: boolean;
  lastSyncedAt: number;
}) {
  if (isSyncing) return "Menyinkronkan…";
  if (isError) return "Belum tersinkron";
  if (!lastSyncedAt) return "Belum pernah sinkron";
  return `Tersinkron ${timeText(new Date(lastSyncedAt))}`;
}

function timeText(date: Date, now: Date = new Date()) {
  const time = new Intl.DateTimeFormat("id", {
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
  if (date.toDateString() === now.toDateString()) return time;
  const day = new Intl.DateTimeFormat("id", {
    day: "numeric",
    month: "short",
  }).format(date);
  return `${day} ${time}`;
}
