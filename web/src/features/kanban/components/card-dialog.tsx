"use client";

import { useState } from "react";
import type { Card, CardStatus } from "../api/kanban-api";
import { fromInputValue, toInputValue } from "../lib/deadline";
import { cardStatuses } from "../lib/statuses";

// Detail kartu: ubah judul dan deskripsi, pindah kolom tanpa menyeret, atau hapus.
export function CardDialog({
  card,
  onSave,
  onMove,
  onDelete,
  onClose,
}: {
  card: Card;
  onSave: (
    title: string,
    description: string,
    deadlineAt: string | null,
  ) => Promise<void>;
  onMove: (status: CardStatus) => Promise<void>;
  onDelete: () => Promise<void>;
  onClose: () => void;
}) {
  const [title, setTitle] = useState(card.title);
  const [description, setDescription] = useState(card.description);
  const [status, setStatus] = useState(card.status);
  const [deadline, setDeadline] = useState(toInputValue(card.deadlineAt));
  const [isBusy, setIsBusy] = useState(false);

  async function run(action: () => Promise<void>) {
    setIsBusy(true);
    try {
      await action();
      onClose();
    } catch {
      // Toast sudah menampilkan sebabnya; dialog tetap terbuka.
    } finally {
      setIsBusy(false);
    }
  }

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    void run(async () => {
      const deadlineAt = fromInputValue(deadline);
      const deadlineChanged = deadline !== toInputValue(card.deadlineAt);
      if (title !== card.title || description !== card.description || deadlineChanged) {
        await onSave(title, description, deadlineAt);
      }
      if (status !== card.status) await onMove(status);
    });
  }

  return (
    <div
      className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4"
      onClick={onClose}
    >
      <form
        role="dialog"
        aria-label="Detail kartu"
        onSubmit={handleSubmit}
        onClick={(event) => event.stopPropagation()}
        className="flex w-full max-w-md flex-col gap-4 rounded-[20px] bg-background p-5"
      >
        <input
          aria-label="Judul kartu"
          required
          maxLength={255}
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          className="bg-transparent text-xl font-semibold outline-none"
        />
        <textarea
          aria-label="Deskripsi"
          placeholder="Deskripsi"
          value={description}
          onChange={(event) => setDescription(event.target.value)}
          className="min-h-32 resize-none rounded-[14px] bg-surface p-3 text-sm outline-none placeholder:text-muted"
        />
        <label className="flex items-center justify-between gap-3 text-sm">
          Kolom
          <select
            value={status}
            onChange={(event) => setStatus(event.target.value as CardStatus)}
            className="rounded-[10px] bg-surface px-3 py-2"
          >
            {cardStatuses.map((item) => (
              <option key={item.status} value={item.status}>
                {item.label}
              </option>
            ))}
          </select>
        </label>
        <label className="flex items-center justify-between gap-3 text-sm">
          Tenggat
          <span className="flex items-center gap-2">
            <input
              type="datetime-local"
              value={deadline}
              onChange={(event) => setDeadline(event.target.value)}
              className="rounded-[10px] bg-surface px-3 py-2"
            />
            {deadline !== "" && (
              <button
                type="button"
                onClick={() => setDeadline("")}
                className="text-sm font-medium text-muted"
              >
                Hapus
              </button>
            )}
          </span>
        </label>
        {card.noteId !== null && (
          <p className="text-xs text-muted">Dibuat dari catatan.</p>
        )}
        <div className="flex items-center gap-2">
          <button
            type="button"
            disabled={isBusy}
            onClick={() => {
              if (window.confirm("Hapus kartu ini?")) void run(onDelete);
            }}
            className="rounded-[14px] px-3 py-2.5 text-sm font-medium text-danger disabled:opacity-40"
          >
            Hapus
          </button>
          <span className="flex-1" />
          <button
            type="button"
            onClick={onClose}
            className="rounded-[14px] px-4 py-2.5 text-sm font-medium text-muted"
          >
            Batal
          </button>
          <button
            type="submit"
            disabled={isBusy || title.trim() === ""}
            className="rounded-[14px] bg-primary px-5 py-2.5 text-sm font-semibold text-on-primary disabled:opacity-40"
          >
            Simpan
          </button>
        </div>
      </form>
    </div>
  );
}
