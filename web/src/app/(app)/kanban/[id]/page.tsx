import { Suspense } from "react";
import { Spinner } from "@/components/spinner";
import { BoardView } from "@/features/kanban/components/board-view";

// ID kerjaan baru diketahui saat halaman dibuka, jadi isinya menyusul setelah kerangka halaman.
export default function Page() {
  return (
    <Suspense fallback={<Spinner />}>
      <BoardView />
    </Suspense>
  );
}
