import { tokenStorage } from "@/features/auth/lib/token-storage";
import { ApiCode } from "./api-codes";
import { showToast } from "./toast";

// Kosong berarti memanggil /api di alamat web itu sendiri (lihat rewrites di next.config.ts).
const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? "";

// Bentuk semua response API, sukses maupun gagal.
type ApiEnvelope<T> = {
  status: boolean;
  title: string;
  code: number;
  data: T | null;
};

export class ApiError extends Error {
  constructor(
    public code: number,
    message: string,
  ) {
    super(message);
  }

  // Belum login, atau sesi sudah tidak berlaku.
  get isUnauthorized() {
    return (
      this.code === ApiCode.UNAUTHENTICATED ||
      this.code === ApiCode.TOKEN_INVALID
    );
  }

  get isUnreachable() {
    return this.code === ApiCode.UNREACHABLE;
  }
}

// Batas waktu menunggu server sebelum permintaan dianggap gagal.
const REQUEST_TIMEOUT_MS = 30_000;

type ApiFetchOptions = {
  // false untuk endpoint publik seperti login, supaya token lama tidak ikut terkirim.
  authenticated?: boolean;
  // Error memunculkan toast secara bawaan. Isi true jika layar menampilkan error-nya sendiri
  // (pesan di form, keadaan kosong dengan "Coba lagi", indikator simpan).
  // Permintaan yang melewati batas waktu tetap memunculkan toast.
  handlesError?: boolean;
};

export async function apiFetch<T>(
  path: string,
  init?: RequestInit,
  { authenticated = true, handlesError = false }: ApiFetchOptions = {},
): Promise<T> {
  const token = authenticated ? tokenStorage.get() : null;

  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}${path}`, {
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      ...init,
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...init?.headers,
      },
    });
  } catch (error) {
    const timedOut =
      error instanceof DOMException && error.name === "TimeoutError";
    const apiError = new ApiError(
      ApiCode.UNREACHABLE,
      timedOut
        ? "Server terlalu lama merespons. Coba lagi."
        : "Server tidak terjangkau. Periksa koneksi Anda.",
    );
    if (timedOut || !handlesError) showToast(apiError.message);
    throw apiError;
  }

  const envelope = await readEnvelope<T>(response);
  if (!envelope) {
    // Jawaban bukan dari backend Manote, misalnya dari proxy saat backend mati.
    const apiError = new ApiError(
      ApiCode.UNREACHABLE,
      "Server sedang tidak bisa dihubungi. Coba lagi nanti.",
    );
    if (!handlesError) showToast(apiError.message);
    throw apiError;
  }

  if (!envelope.status) {
    const error = new ApiError(envelope.code, envelope.title);
    // Sesi tidak berlaku lagi: buang token supaya pengguna bisa login ulang.
    // Halaman login menampilkan pesannya, jadi tidak perlu toast.
    if (error.isUnauthorized && token) {
      tokenStorage.clear();
    } else if (!handlesError) {
      showToast(error.message);
    }
    throw error;
  }
  return envelope.data as T;
}

async function readEnvelope<T>(
  response: Response,
): Promise<ApiEnvelope<T> | null> {
  try {
    const body = (await response.json()) as Partial<ApiEnvelope<T>>;
    if (typeof body.status !== "boolean" || typeof body.code !== "number") {
      return null;
    }
    return body as ApiEnvelope<T>;
  } catch {
    return null;
  }
}
