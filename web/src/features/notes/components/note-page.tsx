"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { AuthPending } from "@/components/auth-pending";
import { Spinner } from "@/components/spinner";
import { useRequireUser } from "@/features/auth/hooks/use-require-user";
import { useNote } from "../hooks/use-notes";
import { NoteEditor } from "./note-editor";

export function NewNotePage() {
  const { user, errorMessage, retry } = useRequireUser();
  if (!user) return <AuthPending errorMessage={errorMessage} onRetry={retry} />;
  return <NoteEditor />;
}

export function ExistingNotePage() {
  const { user, errorMessage, retry } = useRequireUser();
  const { id } = useParams<{ id: string }>();
  const note = useNote(Number(id));

  if (!user) {
    return <AuthPending errorMessage={errorMessage} onRetry={retry} />;
  }
  if (note.isPending) {
    return <Spinner />;
  }
  if (note.isError) {
    return (
      <div className="flex flex-col gap-3 p-8">
        <p role="alert" className="text-danger">
          {note.error.message}
        </p>
        <Link href="/notes" className="text-sm font-medium text-primary">
          Kembali ke catatan
        </Link>
      </div>
    );
  }
  return <NoteEditor key={note.data.id} note={note.data} />;
}
