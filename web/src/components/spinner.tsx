// Indikator memuat saat menunggu jawaban server.
export function Spinner({ label = "Memuat…" }: { label?: string }) {
  return (
    <div
      role="status"
      className="flex flex-1 flex-col items-center justify-center gap-3 p-8 text-sm text-muted"
    >
      <span className="size-8 animate-spin rounded-full border-[3px] border-primary-soft border-t-primary" />
      {label}
    </div>
  );
}
