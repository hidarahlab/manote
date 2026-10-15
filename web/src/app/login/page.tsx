import { Suspense } from "react";
import { LogoMark } from "@/components/logo-mark";
import { LoginForm } from "@/features/auth/components/login-form";
import { LoginNotice } from "@/features/auth/components/login-notice";

export default function LoginPage() {
  return (
    <main className="flex flex-1 items-center justify-center p-6">
      <div className="flex w-full max-w-sm flex-col gap-6">
        <LogoMark />
        <div>
          <h1 className="text-4xl font-bold">Manote</h1>
          <p className="mt-1 text-muted">Meja kerja di saku Anda.</p>
        </div>
        <Suspense fallback={null}>
          <LoginNotice />
        </Suspense>
        <LoginForm />
      </div>
    </main>
  );
}
