import { Suspense } from "react";
import { Spinner } from "@/components/spinner";
import { ExistingNotePage } from "@/features/notes/components/note-page";

// ID catatan baru diketahui saat halaman dibuka, jadi isinya menyusul setelah kerangka halaman.
export default function Page() {
  return (
    <Suspense fallback={<Spinner />}>
      <ExistingNotePage />
    </Suspense>
  );
}
