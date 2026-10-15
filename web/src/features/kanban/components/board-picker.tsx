"use client";

import Link from "next/link";
import type { Board } from "../api/kanban-api";
import { useBoards } from "../hooks/use-boards";

// Dialog untuk memilih kerjaan tujuan, misalnya saat catatan dijadikan kartu.
export function BoardPicker({
  title,
  description,
  onPick,
  onClose,
}: {
  title: string;
  description?: string;
  onPick: (board: Board) => void;
  onClose: () => void;
}) {
  const boards = useBoards();

  return (
    <div
      className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-label={title}
        onClick={(event) => event.stopPropagation()}
        className="flex w-full max-w-sm flex-col gap-3 rounded-[20px] bg-background p-5"
      >
        <h2 className="text-lg font-semibold">{title}</h2>
        {description && <p className="text-sm text-muted">{description}</p>}

        {boards.isPending && <p className="text-sm text-muted">Memuat…</p>}
        {boards.isError && (
          <p role="alert" className="text-sm text-danger">
            {boards.error.message}
          </p>
        )}
        {boards.data?.length === 0 && (
          <p className="text-sm text-muted">
            Belum ada kerjaan.{" "}
            <Link href="/kanban" className="font-medium text-primary">
              Buat kerjaan
            </Link>
          </p>
        )}

        <ul className="flex max-h-72 flex-col gap-2 overflow-y-auto">
          {boards.data?.map((board) => (
            <li key={board.id}>
              <button
                onClick={() => onPick(board)}
                className="w-full rounded-[14px] bg-kanban-bg px-4 py-3 text-left font-medium text-kanban-title"
              >
                {board.name}
              </button>
            </li>
          ))}
        </ul>

        <button
          onClick={onClose}
          className="self-end rounded-[14px] px-4 py-2 text-sm font-medium text-muted"
        >
          Batal
        </button>
      </div>
    </div>
  );
}
