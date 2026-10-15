"use client";

import Link from "next/link";
import { useState } from "react";
import { AuthPending } from "@/components/auth-pending";
import { TrashIcon } from "@/components/icons";
import { Spinner } from "@/components/spinner";
import { SyncBar } from "@/components/sync-bar";
import { useRequireUser } from "@/features/auth/hooks/use-require-user";
import { createBoard, deleteBoard, type Board } from "../api/kanban-api";
import { useBoards, useRefreshKanban } from "../hooks/use-boards";

export function BoardsList() {
  const { user, errorMessage, retry } = useRequireUser();
  const boards = useBoards();
  const refresh = useRefreshKanban();
  const [name, setName] = useState("");
  const [isCreating, setIsCreating] = useState(false);

  if (!user) {
    return <AuthPending errorMessage={errorMessage} onRetry={retry} />;
  }

  async function handleCreate(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (name.trim() === "" || isCreating) return;
    setIsCreating(true);
    try {
      await createBoard(name);
      setName("");
      await refresh();
    } catch {
      // Toast sudah menampilkan sebabnya.
    } finally {
      setIsCreating(false);
    }
  }

  async function handleDelete(board: Board) {
    const warning =
      board.totalCards > 0
        ? `Hapus kerjaan "${board.name}" beserta ${board.totalCards} kartunya?`
        : `Hapus kerjaan "${board.name}"?`;
    if (!window.confirm(warning)) return;
    try {
      await deleteBoard(board.id);
      await refresh();
    } catch {
      // Toast sudah menampilkan sebabnya.
    }
  }

  return (
    <div className="flex w-full flex-1 flex-col gap-5 p-6 lg:p-8">
      <h1 className="text-2xl font-semibold">Kerjaan</h1>

      {/* Sinkron khusus kerjaan: mengambil daftar terbaru dari server. */}
      <SyncBar
        isSyncing={boards.isFetching}
        isError={boards.isError}
        lastSyncedAt={boards.dataUpdatedAt}
        onSync={() => void boards.refetch()}
      />

      <form onSubmit={handleCreate} className="flex max-w-xl gap-2">
        <input
          aria-label="Nama kerjaan baru"
          placeholder="Nama kerjaan baru"
          maxLength={100}
          value={name}
          onChange={(event) => setName(event.target.value)}
          className="min-w-0 flex-1 rounded-[14px] bg-surface px-4 py-3 outline-none placeholder:text-muted focus:outline-2 focus:outline-primary"
        />
        <button
          type="submit"
          disabled={name.trim() === "" || isCreating}
          className="rounded-[14px] bg-primary px-5 py-3 font-semibold text-on-primary disabled:opacity-40"
        >
          Buat
        </button>
      </form>

      {boards.isPending && <Spinner />}

      {boards.isError && (
        <p role="alert" className="text-sm text-danger">
          {boards.error.message}
        </p>
      )}

      {boards.data?.length === 0 && (
        <div className="flex flex-1 flex-col items-center justify-center gap-2 text-center">
          <h2 className="text-lg font-semibold">Buat kerjaan pertama Anda</h2>
          <p className="text-muted">
            Satu kerjaan adalah satu papan kanban: Backlog, Todo, In Progress,
            Review, dan Done.
          </p>
        </div>
      )}

      {boards.data && boards.data.length > 0 && (
        <ul className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
          {boards.data.map((board) => (
            <li
              key={board.id}
              className="flex items-center gap-2 rounded-[20px] bg-kanban-bg pr-2"
            >
              <Link
                href={`/kanban/${board.id}`}
                className="flex min-w-0 flex-1 flex-col gap-1 p-4"
              >
                <h2 className="truncate font-semibold text-kanban-title">
                  {board.name}
                </h2>
                <p className="text-sm text-kanban-sub">
                  {board.totalCards === 0
                    ? "Belum ada kartu"
                    : `${board.doneCards} dari ${board.totalCards} kartu selesai`}
                </p>
              </Link>
              <button
                onClick={() => void handleDelete(board)}
                aria-label={`Hapus kerjaan ${board.name}`}
                title="Hapus kerjaan"
                className="flex size-9 shrink-0 items-center justify-center rounded-full text-kanban-sub hover:text-danger"
              >
                <TrashIcon width={18} height={18} />
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
