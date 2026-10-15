import { Spinner } from "./spinner";

// Ditampilkan selama data pengguna belum ada: sedang memuat, atau gagal dimuat.
export function AuthPending({
  errorMessage,
  onRetry,
}: {
  errorMessage: string | null;
  onRetry: () => void;
}) {
  if (!errorMessage) {
    return <Spinner />;
  }
  return (
    <div className="flex flex-1 flex-col items-center justify-center gap-3 p-8 text-center">
      <p role="alert" className="text-danger">
        {errorMessage}
      </p>
      <button
        onClick={onRetry}
        className="rounded-[14px] bg-primary px-5 py-2.5 font-semibold text-on-primary"
      >
        Coba lagi
      </button>
    </div>
  );
}
