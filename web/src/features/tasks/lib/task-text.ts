export function startText(iso: string): string {
  const text = new Intl.DateTimeFormat("id", {
    day: "numeric",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(iso));
  return `Mulai ${text}`;
}

// Nilai untuk <input type="datetime-local">, dalam waktu setempat.
export function toInputValue(date: Date): string {
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60_000);
  return local.toISOString().slice(0, 16);
}

// Jam bulat berikutnya, sebagai nilai awal tugas baru.
export function defaultStart(now: Date = new Date()): string {
  const next = new Date(now);
  next.setHours(next.getHours() + 1, 0, 0, 0);
  return toInputValue(next);
}
