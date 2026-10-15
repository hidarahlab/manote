import type { Card, CardStatus } from "../api/kanban-api";

// Meniru aturan pindah di server: keluarkan kartu, sisipkan di posisi tujuan, lalu
// rapikan urutan kolom asal dan tujuan. Dipakai supaya papan langsung berubah di layar.
export function applyMove(
  cards: Card[],
  cardId: number,
  status: CardStatus,
  position: number,
): Card[] {
  const moving = cards.find((card) => card.id === cardId);
  if (!moving) return cards;

  const column = (target: CardStatus) =>
    cards
      .filter((card) => card.status === target && card.id !== cardId)
      .sort((a, b) => a.position - b.position);

  const target = column(status);
  // Waktu selesai ikut berubah saat kartu masuk atau keluar dari Done, seperti di server.
  const doneAt =
    status === moving.status
      ? moving.doneAt
      : status === "DONE"
        ? new Date().toISOString()
        : null;
  target.splice(Math.min(position, target.length), 0, { ...moving, status, doneAt });
  const source = moving.status === status ? [] : column(moving.status);

  const renumbered = new Map<number, Card>();
  [target, source].forEach((list) =>
    list.forEach((card, index) =>
      renumbered.set(card.id, { ...card, position: index }),
    ),
  );
  return cards.map((card) => renumbered.get(card.id) ?? card);
}

export function cardsIn(cards: Card[], status: CardStatus): Card[] {
  return cards
    .filter((card) => card.status === status)
    .sort((a, b) => a.position - b.position);
}
