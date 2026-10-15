import { apiFetch } from "@/lib/api-client";

export type User = {
  userId: string;
  email: string;
  fullName: string;
  userType: "USER" | "ADMIN";
};

export type LoginRequest = {
  username: string;
  password: string;
};

export type LoginResponse = {
  accessToken: string;
  expiresIn: number;
  user: User;
};

export function login(request: LoginRequest) {
  return apiFetch<LoginResponse>(
    "/api/auth/login",
    { method: "POST", body: JSON.stringify(request) },
    { authenticated: false, handlesError: true },
  );
}

export function getCurrentUser() {
  return apiFetch<User>("/api/auth/me", undefined, { handlesError: true });
}
