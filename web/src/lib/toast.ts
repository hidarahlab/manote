// Satu tempat untuk memunculkan toast error dari mana pun di web.
export type ToastKind = "error" | "success";
export type Toast = { id: number; message: string; kind: ToastKind };

const DURATION_MS = 4000;

let current: Toast | null = null;
let nextId = 1;
let dismissTimer: ReturnType<typeof setTimeout> | undefined;
const listeners = new Set<() => void>();

function emit(toast: Toast | null) {
  current = toast;
  listeners.forEach((listener) => listener());
}

export function showToast(message: string, kind: ToastKind = "error") {
  // Pesan yang sama sedang tampil: cukup perpanjang waktunya, jangan menumpuk.
  if (current?.message !== message || current.kind !== kind) {
    emit({ id: nextId++, message, kind });
  }
  clearTimeout(dismissTimer);
  dismissTimer = setTimeout(() => emit(null), DURATION_MS);
}

export function dismissToast() {
  clearTimeout(dismissTimer);
  emit(null);
}

export function subscribeToast(listener: () => void) {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
}

export function getToast() {
  return current;
}
