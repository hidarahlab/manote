"use client";

import { useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import {
  AlarmIcon,
  ChevronLeftIcon,
  KanbanIcon,
  TrashIcon,
} from "@/components/icons";
import { createCard, type Board } from "@/features/kanban/api/kanban-api";
import { BoardPicker } from "@/features/kanban/components/board-picker";
import { boardsQueryKey } from "@/features/kanban/hooks/use-boards";
import { createTask } from "@/features/tasks/api/tasks-api";
import { tasksQueryKey } from "@/features/tasks/hooks/use-tasks";
import { defaultStart, toInputValue } from "@/features/tasks/lib/task-text";
import { showToast } from "@/lib/toast";
import {
  createNote,
  deleteNote,
  updateNote,
  type Note,
  type NoteDraft,
} from "../api/notes-api";
import { notesQueryKey } from "../hooks/use-notes";
import { displayTitle, isBlank } from "../lib/note-text";

const AUTOSAVE_DELAY_MS = 700;

type SaveStatus = "idle" | "saving" | "saved" | "error";

const statusLabel: Record<SaveStatus, string> = {
  idle: "",
  saving: "Menyimpan…",
  saved: "Tersimpan",
  error: "Gagal menyimpan",
};

// Tanpa `note`, editor membuat catatan baru saat pertama kali ada isinya.
export function NoteEditor({ note }: { note?: Note }) {
  const router = useRouter();
  const queryClient = useQueryClient();
  const [title, setTitle] = useState(note?.title ?? "");
  const [content, setContent] = useState(note?.content ?? "");
  const [status, setStatus] = useState<SaveStatus>("idle");

  const [isPickingBoard, setIsPickingBoard] = useState(false);
  // Waktu mulai yang sedang dipilih di dialog "Jadikan tugas"; null berarti dialog tertutup.
  const [taskStart, setTaskStart] = useState<string | null>(null);

  const noteIdRef = useRef<number | null>(note?.id ?? null);
  const noteClientIdRef = useRef<string | null>(note?.clientId ?? null);
  const draftRef = useRef<NoteDraft>({ title, content });
  const savedRef = useRef<NoteDraft>({ title, content });
  const savingRef = useRef<Promise<void> | null>(null);
  const closedRef = useRef(false);
  // Catatan sudah dipindahkan menjadi kartu dan dihapus; tidak boleh disimpan lagi.
  const movedRef = useRef(false);
  const contentRef = useRef<HTMLTextAreaElement>(null);

  const save = useCallback(async () => {
    if (movedRef.current) return;
    if (savingRef.current) await savingRef.current;

    const draft = draftRef.current;
    const saved = savedRef.current;
    if (draft.title === saved.title && draft.content === saved.content) return;
    if (noteIdRef.current === null && isBlank(draft)) return;

    setStatus("saving");
    savingRef.current = (async () => {
      try {
        if (noteIdRef.current === null) {
          const created = await createNote(draft);
          noteIdRef.current = created.id;
          noteClientIdRef.current = created.clientId;
          window.history.replaceState(null, "", `/notes/${created.id}`);
        } else {
          await updateNote(noteIdRef.current, draft);
        }
        savedRef.current = draft;
        setStatus("saved");
      } catch {
        setStatus("error");
      } finally {
        savingRef.current = null;
      }
    })();
    await savingRef.current;
  }, []);

  // Simpan perubahan terakhir, buang catatan yang kosong, lalu segarkan daftar.
  const close = useCallback(async () => {
    if (closedRef.current) return;
    closedRef.current = true;
    await save();
    if (noteIdRef.current !== null && isBlank(draftRef.current)) {
      await deleteNote(noteIdRef.current, { silent: true }).catch(
        () => undefined,
      );
    }
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: notesQueryKey }),
      queryClient.invalidateQueries({ queryKey: ["dashboard"] }),
    ]);
  }, [queryClient, save]);

  useEffect(() => {
    draftRef.current = { title, content };
    const timer = setTimeout(() => void save(), AUTOSAVE_DELAY_MS);
    return () => clearTimeout(timer);
  }, [title, content, save]);

  useEffect(() => {
    closedRef.current = false;
    return () => void close();
  }, [close]);

  async function handleBack() {
    await close();
    router.push("/notes");
  }

  // Catatan ini dipindahkan menjadi kartu di Backlog kerjaan yang dipilih: pengingatnya
  // menjadi tenggat kartu, dan catatannya dihapus oleh server.
  async function handleAssign(board: Board) {
    setIsPickingBoard(false);
    await save();
    const noteClientId = noteClientIdRef.current;
    if (noteClientId === null) {
      showToast("Tulis catatan dulu sebelum dijadikan kerjaan.");
      return;
    }
    try {
      await createCard(board.id, {
        title: displayTitle(draftRef.current),
        description: draftRef.current.content,
        noteClientId,
      });
    } catch {
      // Toast sudah menampilkan sebabnya.
      return;
    }
    // Catatannya sudah tidak ada: jangan disimpan lagi, lalu kembali ke daftar.
    movedRef.current = true;
    closedRef.current = true;
    showToast(`Dipindahkan ke Backlog "${board.name}"`, "success");
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: notesQueryKey }),
      queryClient.invalidateQueries({ queryKey: boardsQueryKey }),
      queryClient.invalidateQueries({ queryKey: ["dashboard"] }),
    ]);
    router.push("/notes");
  }

  // Waktu mulai yang ditawarkan: pengingat catatan jika ada dan belum lewat, kalau tidak
  // jam bulat berikutnya.
  function openTaskDialog() {
    const reminder = note?.reminderAt ? new Date(note.reminderAt) : null;
    setTaskStart(
      reminder && reminder.getTime() > Date.now()
        ? toInputValue(reminder)
        : defaultStart(),
    );
  }

  // Catatan ini dipindahkan menjadi tugas: judulnya menjadi nama tugas, isinya menjadi
  // keterangan, dan catatannya dihapus oleh server.
  async function handleMakeTask(startAt: string) {
    setTaskStart(null);
    await save();
    const noteClientId = noteClientIdRef.current;
    if (noteClientId === null) {
      showToast("Tulis catatan dulu sebelum dijadikan tugas.");
      return;
    }
    try {
      await createTask({
        title: displayTitle(draftRef.current),
        description: draftRef.current.content,
        startAt: new Date(startAt).toISOString(),
        noteClientId,
      });
    } catch {
      // Toast sudah menampilkan sebabnya.
      return;
    }
    // Catatannya sudah tidak ada: jangan disimpan lagi, lalu kembali ke daftar.
    movedRef.current = true;
    closedRef.current = true;
    showToast("Dipindahkan ke Tugas", "success");
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: notesQueryKey }),
      queryClient.invalidateQueries({ queryKey: tasksQueryKey }),
      queryClient.invalidateQueries({ queryKey: ["dashboard"] }),
    ]);
    router.push("/notes");
  }

  async function handleDelete() {
    if (!window.confirm("Hapus catatan ini?")) return;
    closedRef.current = true;
    if (savingRef.current) await savingRef.current;
    if (noteIdRef.current !== null) {
      try {
        await deleteNote(noteIdRef.current);
      } catch {
        // Toast sudah menampilkan sebabnya; tetap di editor supaya bisa dicoba lagi.
        closedRef.current = false;
        return;
      }
    }
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: notesQueryKey }),
      queryClient.invalidateQueries({ queryKey: ["dashboard"] }),
    ]);
    router.push("/notes");
  }

  return (
    <div className="flex w-full flex-1 flex-col gap-4 p-6 lg:p-8">
      <div className="flex items-center gap-3">
        <button
          onClick={handleBack}
          className="flex items-center gap-1 text-sm font-medium text-primary"
        >
          <ChevronLeftIcon width={16} height={16} />
          Catatan
        </button>
        <p
          aria-live="polite"
          className={`flex-1 text-right text-xs ${status === "error" ? "text-danger" : "text-muted"}`}
        >
          {statusLabel[status]}
        </p>
        <button
          onClick={() => setIsPickingBoard(true)}
          aria-label="Jadikan kerjaan"
          title="Jadikan kerjaan"
          className="flex size-9 items-center justify-center rounded-full text-muted hover:bg-surface hover:text-primary"
        >
          <KanbanIcon width={18} height={18} />
        </button>
        <button
          onClick={openTaskDialog}
          aria-label="Jadikan tugas"
          title="Jadikan tugas"
          className="flex size-9 items-center justify-center rounded-full text-muted hover:bg-surface hover:text-primary"
        >
          <AlarmIcon width={18} height={18} />
        </button>
        <button
          onClick={handleDelete}
          aria-label="Hapus catatan"
          title="Hapus catatan"
          className="flex size-9 items-center justify-center rounded-full text-muted hover:bg-surface hover:text-danger"
        >
          <TrashIcon width={18} height={18} />
        </button>
      </div>

      <input
        aria-label="Judul"
        placeholder="Judul"
        maxLength={255}
        autoFocus={!note}
        value={title}
        onChange={(event) => setTitle(event.target.value)}
        onKeyDown={(event) => {
          if (event.key === "Enter") {
            event.preventDefault();
            contentRef.current?.focus();
          }
        }}
        className="bg-transparent text-2xl font-semibold outline-none placeholder:text-muted"
      />
      <textarea
        ref={contentRef}
        aria-label="Isi catatan"
        placeholder="Tulis catatan…"
        value={content}
        onChange={(event) => setContent(event.target.value)}
        className="min-h-80 flex-1 resize-none bg-transparent leading-relaxed outline-none placeholder:text-muted"
      />

      {taskStart !== null && (
        <div
          className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4"
          onClick={() => setTaskStart(null)}
        >
          <form
            role="dialog"
            aria-label="Jadikan tugas"
            onClick={(event) => event.stopPropagation()}
            onSubmit={(event) => {
              event.preventDefault();
              void handleMakeTask(taskStart);
            }}
            className="flex w-full max-w-sm flex-col gap-4 rounded-[20px] bg-background p-5"
          >
            <h2 className="text-lg font-semibold">Jadikan tugas</h2>
            <p className="text-sm text-muted">
              Catatan dipindahkan menjadi tugas, lalu dihapus dari Catatan.
              Judulnya menjadi nama tugas, isinya menjadi keterangan, dan alarm
              berbunyi pada waktu mulai.
            </p>
            <label className="flex items-center justify-between gap-3 text-sm">
              Mulai
              <input
                type="datetime-local"
                required
                value={taskStart}
                onChange={(event) => setTaskStart(event.target.value)}
                className="rounded-[10px] bg-surface px-3 py-2"
              />
            </label>
            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setTaskStart(null)}
                className="rounded-[14px] px-4 py-2.5 text-sm font-medium text-muted"
              >
                Batal
              </button>
              <button
                type="submit"
                className="rounded-[14px] bg-primary px-5 py-2.5 text-sm font-semibold text-on-primary"
              >
                Jadikan tugas
              </button>
            </div>
          </form>
        </div>
      )}

      {isPickingBoard && (
        <BoardPicker
          title="Jadikan kerjaan di…"
          description="Catatan dipindahkan menjadi kartu di Backlog, lalu dihapus dari Catatan. Pengingatnya menjadi tenggat kartu."
          onPick={(board) => void handleAssign(board)}
          onClose={() => setIsPickingBoard(false)}
        />
      )}
    </div>
  );
}
