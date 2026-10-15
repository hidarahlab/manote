"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { EyeIcon, EyeOffIcon, LockIcon, UserIcon } from "@/components/icons";
import { useLogin } from "../hooks/use-login";

const fieldClass =
  "flex items-center gap-3 rounded-[14px] bg-surface px-4 py-3.5 focus-within:outline-2 focus-within:outline-primary";
const inputClass =
  "min-w-0 flex-1 bg-transparent outline-none placeholder:text-muted";

export function LoginForm() {
  const router = useRouter();
  const login = useLogin();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [isPasswordVisible, setIsPasswordVisible] = useState(false);

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    login.mutate(
      { username, password },
      { onSuccess: () => router.replace("/dashboard") },
    );
  }

  return (
    <form onSubmit={handleSubmit} className="flex w-full flex-col gap-4">
      <label className={fieldClass}>
        <UserIcon className="shrink-0 text-primary" />
        <input
          name="username"
          aria-label="User ID atau email"
          placeholder="User ID atau email"
          autoComplete="username"
          autoCapitalize="none"
          required
          value={username}
          onChange={(event) => setUsername(event.target.value)}
          className={inputClass}
        />
      </label>
      <div className={fieldClass}>
        <LockIcon className="shrink-0 text-primary" />
        <input
          name="password"
          aria-label="Password"
          placeholder="Password"
          type={isPasswordVisible ? "text" : "password"}
          autoComplete="current-password"
          required
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          className={inputClass}
        />
        <button
          type="button"
          onClick={() => setIsPasswordVisible((visible) => !visible)}
          aria-label={
            isPasswordVisible ? "Sembunyikan password" : "Tampilkan password"
          }
          className="shrink-0 text-muted"
        >
          {isPasswordVisible ? <EyeOffIcon /> : <EyeIcon />}
        </button>
      </div>
      {login.isError && (
        <p role="alert" className="text-sm text-danger">
          {login.error.message}
        </p>
      )}
      <button
        type="submit"
        disabled={login.isPending}
        className="mt-2 rounded-[14px] bg-primary px-4 py-3.5 font-semibold text-on-primary disabled:opacity-40"
      >
        {login.isPending && (
          <span className="mr-2 inline-block size-4 animate-spin rounded-full border-2 border-on-primary/40 border-t-on-primary align-[-2px]" />
        )}
        {login.isPending ? "Masuk…" : "Masuk"}
      </button>
    </form>
  );
}
