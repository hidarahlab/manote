"use client";

import Link from "next/link";
import { AuthPending } from "@/components/auth-pending";
import { PlusIcon } from "@/components/icons";
import { Spinner } from "@/components/spinner";
import { SyncBar } from "@/components/sync-bar";
import { useRequireUser } from "@/features/auth/hooks/use-require-user";
import { useNotes } from "../hooks/use-notes";
import { displayTitle, preview, relativeTime } from "../lib/note-text";

export function NotesList() {
  const { user, errorMessage, retry } = useRequireUser();
  const notes = useNotes();

  if (!user) {
    return <AuthPending errorMessage={errorMessage} onRetry={retry} />;
  }

  return (
    <div className="flex w-full flex-1 flex-col gap-5 p-6 lg:p-8">
      <header className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Catatan</h1>
        <Link
          href="/notes/new"
          aria-label="Buat catatan"
          title="Buat catatan"
          className="flex size-11 items-center justify-center rounded-full bg-primary text-on-primary"
        >
          <PlusIcon />
        </Link>
      </header>

      {/* Sinkron khusus catatan: mengambil daftar terbaru dari server. */}
      <SyncBar
        isSyncing={notes.isFetching}
        isError={notes.isError}
        lastSyncedAt={notes.dataUpdatedAt}
        onSync={() => void notes.refetch()}
      />

      {notes.isPending && <Spinner />}

      {notes.isError && (
        <p role="alert" className="text-sm text-danger">
          {notes.error.message}
        </p>
      )}

      {notes.data?.length === 0 && (
        <div className="flex flex-1 flex-col items-center justify-center gap-3 text-center">
          <h2 className="text-lg font-semibold">Tulis catatan pertama Anda</h2>
          <p className="text-muted">
            Catat pekerjaan, ide, atau hasil rapat supaya tidak lupa.
          </p>
          <Link
            href="/notes/new"
            className="mt-2 rounded-[14px] bg-primary px-5 py-3 font-semibold text-on-primary"
          >
            Buat catatan
          </Link>
        </div>
      )}

      {notes.data && notes.data.length > 0 && (
        <ul className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
          {notes.data.map((note) => (
            <li key={note.id}>
              <Link
                href={`/notes/${note.id}`}
                className="flex h-full flex-col gap-1 rounded-[20px] bg-notes-bg p-4"
              >
                <h2 className="truncate font-semibold text-notes-title">
                  {displayTitle(note)}
                </h2>
                {preview(note) !== "" && (
                  <p className="line-clamp-2 text-sm text-notes-sub">
                    {preview(note)}
                  </p>
                )}
                <p className="text-xs text-notes-sub" suppressHydrationWarning>
                  Diubah {relativeTime(note.updatedAt)}
                </p>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
