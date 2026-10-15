// Kode di field `code` response API. Kode khusus Manote memakai kode HTTP induknya
// ditambah satu digit urut, misalnya 4011 dan 4012 adalah turunan 401.
export const ApiCode = {
  // Bukan dari server: permintaan tidak sampai atau jawabannya tidak dikenali.
  UNREACHABLE: 0,
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  VALIDATION_FAILED: 4001,
  UNAUTHENTICATED: 401,
  INVALID_CREDENTIALS: 4011,
  TOKEN_INVALID: 4012,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  TOO_MANY_REQUESTS: 429,
  LOGIN_LOCKED: 4291,
  INTERNAL_ERROR: 500,
} as const;
