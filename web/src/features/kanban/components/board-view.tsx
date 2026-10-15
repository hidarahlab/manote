"use client";

import {
  DndContext,
  DragOverlay,
  PointerSensor,
  closestCorners,
  useDroppable,
  useSensor,
  useSensors,
  type DragEndEvent,
  type DragStartEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  useSortable,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useState } from "react";
import { AuthPending } from "@/components/auth-pending";
import { ChevronLeftIcon } from "@/components/icons";
import { Spinner } from "@/components/spinner";
import { SyncBar } from "@/components/sync-bar";
import { useRequireUser } from "@/features/auth/hooks/use-require-user";
import {
  createCard,
  deleteCard,
  moveCard,
  updateCard,
  type BoardDetail,
  type Card,
  type CardStatus,
} from "../api/kanban-api";
import { boardQueryKey, useBoard, useRefreshKanban } from "../hooks/use-boards";
import {
  deadlineClasses,
  deadlineLevel,
  deadlineText,
  doneText,
} from "../lib/deadline";
import { applyMove, cardsIn } from "../lib/move";
import { cardStatuses } from "../lib/statuses";
import { CardDialog } from "./card-dialog";

const columnId = (status: CardStatus) => `column:${status}`;

export function BoardView() {
  const { user, errorMessage, retry } = useRequireUser();
  const { id } = useParams<{ id: string }>();
  const boardId = Number(id);
  const board = useBoard(boardId);
  const queryClient = useQueryClient();
  const refresh = useRefreshKanban();
  const [draggingId, setDraggingId] = useState<number | null>(null);
  const [openCardId, setOpenCardId] = useState<number | null>(null);
  // Jarak kecil sebelum dianggap menyeret, supaya klik biasa tetap membuka kartu.
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } }),
  );

  if (!user) {
    return <AuthPending errorMessage={errorMessage} onRetry={retry} />;
  }
  if (board.isPending) return <Spinner />;
  if (board.isError) {
    return (
      <div className="flex flex-col gap-3 p-8">
        <p role="alert" className="text-danger">
          {board.error.message}
        </p>
        <Link href="/kanban" className="text-sm font-medium text-primary">
          Kembali ke kerjaan
        </Link>
      </div>
    );
  }

  const cards = board.data.cards;
  const openCard = cards.find((card) => card.id === openCardId);
  const draggingCard = cards.find((card) => card.id === draggingId);

  // Papan langsung berubah di layar, lalu disamakan dengan server.
  async function move(cardId: number, status: CardStatus, position: number) {
    queryClient.setQueryData<BoardDetail>(boardQueryKey(boardId), (current) =>
      current
        ? { ...current, cards: applyMove(current.cards, cardId, status, position) }
        : current,
    );
    try {
      await moveCard(cardId, status, position);
    } catch {
      // Toast sudah menampilkan sebabnya; papan dikembalikan oleh refresh di bawah.
    }
    await refresh();
  }

  function handleDragStart(event: DragStartEvent) {
    setDraggingId(Number(event.active.id));
  }

  function handleDragEnd(event: DragEndEvent) {
    setDraggingId(null);
    const { active, over } = event;
    if (!over) return;

    const cardId = Number(active.id);
    const moving = cards.find((card) => card.id === cardId);
    if (!moving) return;

    let status: CardStatus;
    let position: number;
    if (typeof over.id === "string" && over.id.startsWith("column:")) {
      // Dilepas di area kolom: taruh paling bawah.
      status = over.id.slice("column:".length) as CardStatus;
      position = cardsIn(cards, status).filter((card) => card.id !== cardId).length;
    } else {
      // Dilepas di atas kartu lain: ambil tempat kartu itu.
      const target = cards.find((card) => card.id === Number(over.id));
      if (!target) return;
      status = target.status;
      position = target.position;
    }
    if (status === moving.status && position === moving.position) return;
    void move(cardId, status, position);
  }

  async function addCard(status: CardStatus, title: string) {
    await createCard(boardId, { title, status });
    await refresh();
  }

  return (
    <div className="flex w-full min-w-0 flex-1 flex-col gap-5 p-6 lg:p-8">
      <Link
        href="/kanban"
        className="flex items-center gap-1 self-start text-sm font-medium text-primary"
      >
        <ChevronLeftIcon width={16} height={16} />
        Kerjaan
      </Link>

      <h1 className="text-2xl font-semibold">{board.data.name}</h1>

      {/* Sinkron khusus papan ini: mengambil kartu terbaru dari server. */}
      <SyncBar
        isSyncing={board.isFetching}
        isError={board.isError}
        lastSyncedAt={board.dataUpdatedAt}
        onSync={() => void board.refetch()}
      />

      <DndContext
        sensors={sensors}
        collisionDetection={closestCorners}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
        onDragCancel={() => setDraggingId(null)}
      >
        <div className="flex flex-1 items-start gap-3 overflow-x-auto pb-4">
          {cardStatuses.map(({ status, label }) => (
            <Column
              key={status}
              status={status}
              label={label}
              cards={cardsIn(cards, status)}
              onOpen={setOpenCardId}
              onAdd={(title) => addCard(status, title)}
            />
          ))}
        </div>
        <DragOverlay>
          {draggingCard && <CardFace card={draggingCard} isOverlay />}
        </DragOverlay>
      </DndContext>

      {openCard && (
        <CardDialog
          key={openCard.id}
          card={openCard}
          onClose={() => setOpenCardId(null)}
          onSave={async (title, description, deadlineAt) => {
            await updateCard(openCard.id, { title, description, deadlineAt });
            await refresh();
          }}
          onMove={(status) =>
            move(openCard.id, status, cardsIn(cards, status).length)
          }
          onDelete={async () => {
            await deleteCard(openCard.id);
            await refresh();
          }}
        />
      )}
    </div>
  );
}

function Column({
  status,
  label,
  cards,
  onOpen,
  onAdd,
}: {
  status: CardStatus;
  label: string;
  cards: Card[];
  onOpen: (cardId: number) => void;
  onAdd: (title: string) => Promise<void>;
}) {
  const { setNodeRef, isOver } = useDroppable({ id: columnId(status) });

  return (
    <section
      ref={setNodeRef}
      aria-label={label}
      className={`flex w-64 shrink-0 flex-col gap-2 rounded-[20px] bg-surface p-3 xl:w-auto xl:min-w-56 xl:flex-1 ${isOver ? "outline-2 outline-primary" : ""}`}
    >
      <h2 className="flex items-center justify-between px-1 text-sm font-semibold">
        {label}
        <span className="font-normal text-muted">{cards.length}</span>
      </h2>
      <SortableContext
        items={cards.map((card) => card.id)}
        strategy={verticalListSortingStrategy}
      >
        <ul className="flex min-h-4 flex-col gap-2">
          {cards.map((card) => (
            <SortableCard key={card.id} card={card} onOpen={onOpen} />
          ))}
        </ul>
      </SortableContext>
      <AddCard onAdd={onAdd} />
    </section>
  );
}

function SortableCard({
  card,
  onOpen,
}: {
  card: Card;
  onOpen: (cardId: number) => void;
}) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } =
    useSortable({ id: card.id });

  return (
    <li
      ref={setNodeRef}
      style={{ transform: CSS.Transform.toString(transform), transition }}
      className={isDragging ? "opacity-40" : ""}
      {...attributes}
      {...listeners}
      onClick={() => onOpen(card.id)}
    >
      <CardFace card={card} />
    </li>
  );
}

function CardFace({ card, isOverlay = false }: { card: Card; isOverlay?: boolean }) {
  // Warna kartu mengikuti sisa waktu ke tenggat (lihat deadlineLevel).
  const level = deadlineLevel(card);
  const classes = deadlineClasses[level];

  return (
    <div
      data-deadline={level}
      className={`cursor-grab rounded-[14px] p-3 text-sm ${classes.card} ${isOverlay ? "shadow-lg" : ""}`}
    >
      <p className={`font-medium ${classes.title}`}>{card.title}</p>
      {level === "done" ? (
        // Kartu selesai hanya menampilkan judul dan waktu selesainya.
        <p className={`mt-1 text-xs font-medium ${classes.text}`} suppressHydrationWarning>
          {doneText(card)}
        </p>
      ) : (
        <>
          {card.description.trim() !== "" && (
            <p className={`mt-1 line-clamp-2 text-xs ${classes.text}`}>
              {card.description}
            </p>
          )}
          {card.deadlineAt && (
            <p
              className={`mt-2 text-xs font-medium ${classes.text}`}
              suppressHydrationWarning
            >
              Tenggat {deadlineText(card.deadlineAt)}
            </p>
          )}
        </>
      )}
    </div>
  );
}

// Kolom ketik di bawah tiap kolom: Enter menambah kartu dan kolom ketik tetap terbuka.
function AddCard({ onAdd }: { onAdd: (title: string) => Promise<void> }) {
  const [isOpen, setIsOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [isAdding, setIsAdding] = useState(false);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (title.trim() === "" || isAdding) return;
    setIsAdding(true);
    try {
      await onAdd(title);
      setTitle("");
    } catch {
      // Toast sudah menampilkan sebabnya.
    } finally {
      setIsAdding(false);
    }
  }

  if (!isOpen) {
    return (
      <button
        onClick={() => setIsOpen(true)}
        className="rounded-[14px] px-2 py-1.5 text-left text-sm text-muted hover:text-primary"
      >
        + Tambah
      </button>
    );
  }
  return (
    <form onSubmit={handleSubmit}>
      <input
        autoFocus
        aria-label="Judul kartu baru"
        placeholder="Judul kartu, lalu Enter"
        maxLength={255}
        value={title}
        onChange={(event) => setTitle(event.target.value)}
        onBlur={() => {
          if (title.trim() === "") setIsOpen(false);
        }}
        onKeyDown={(event) => {
          if (event.key === "Escape") {
            setTitle("");
            setIsOpen(false);
          }
        }}
        className="w-full rounded-[14px] bg-background p-3 text-sm outline-none placeholder:text-muted focus:outline-2 focus:outline-primary"
      />
    </form>
  );
}
