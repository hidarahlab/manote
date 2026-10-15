"use client";

import { useEffect, useState } from "react";
import { AuthPending } from "@/components/auth-pending";
import { TrashIcon } from "@/components/icons";
import { Spinner } from "@/components/spinner";
import { SyncBar } from "@/components/sync-bar";
import { useRequireUser } from "@/features/auth/hooks/use-require-user";
import {
  createTask,
  deleteTask,
  updateTask,
  type TaskItem,
} from "../api/tasks-api";
import { useRefreshTasks, useTasks } from "../hooks/use-tasks";
import { defaultStart, startText, toInputValue } from "../lib/task-text";

export function TasksList() {
  const { user, errorMessage, retry } = useRequireUser();
  const tasks = useTasks();
  const refresh = useRefreshTasks();
  const [title, setTitle] = useState("");
  const [startAt, setStartAt] = useState("");
  const [isCreating, setIsCreating] = useState(false);
  const [editing, setEditing] = useState<TaskItem | null>(null);
  const [notificationPermission, setNotificationPermission] = useState<
    NotificationPermission | "unsupported" | null
  >(null);
  // Diperbarui berkala supaya tanda "lewat waktu" muncul tanpa memuat ulang.
  // Jam hanya dibaca di browser, setelah halaman tampil; 0 berarti belum dibaca.
  const [now, setNow] = useState(0);

  useEffect(() => {
    const read = () =>
      setNotificationPermission(
        "Notification" in window ? Notification.permission : "unsupported",
      );
    const timer = setInterval(() => setNow(Date.now()), 15_000);
    // Dibaca setelah halaman tampil, karena izin notifikasi hanya ada di browser.
    const initial = setTimeout(() => {
      read();
      setNow(Date.now());
    }, 0);
    return () => {
      clearInterval(timer);
      clearTimeout(initial);
    };
  }, []);

  if (!user) {
    return <AuthPending errorMessage={errorMessage} onRetry={retry} />;
  }

  // Aksi di bawah ini memakai toast untuk error; halaman cukup memuat ulang datanya.
  async function run(action: () => Promise<unknown>) {
    try {
      await action();
    } catch {
      // Toast sudah menampilkan sebabnya.
    }
    await refresh();
  }

  async function handleCreate(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (title.trim() === "" || isCreating) return;
    setIsCreating(true);
    try {
      await createTask({
        title,
        startAt: new Date(startAt || defaultStart()).toISOString(),
      });
      setTitle("");
      setStartAt("");
    } catch {
      // Toast sudah menampilkan sebabnya.
    }
    await refresh();
    setIsCreating(false);
  }

  const setDone = (task: TaskItem, done: boolean) =>
    run(() => updateTask(task.id, { title: task.title, startAt: task.startAt, done }));

  const pending = tasks.data?.filter((task) => !task.done) ?? [];
  const done = (tasks.data?.filter((task) => task.done) ?? []).sort((a, b) =>
    (b.doneAt ?? "").localeCompare(a.doneAt ?? ""),
  );

  function renderTask(task: TaskItem) {
    const isDue = !task.done && now > 0 && new Date(task.startAt).getTime() <= now;
    return (
      <li
        key={task.id}
        className="flex items-start gap-3 rounded-[20px] bg-tasks-bg p-4"
      >
        <input
          type="checkbox"
          checked={task.done}
          onChange={(event) => void setDone(task, event.target.checked)}
          aria-label={task.done ? "Tandai belum selesai" : "Tandai selesai"}
          className="mt-1 size-5 accent-primary"
        />
        <button
          onClick={() => setEditing(task)}
          className="flex min-w-0 flex-1 flex-col gap-1 text-left"
        >
          <span
            className={`truncate font-semibold text-tasks-title ${task.done ? "line-through" : ""}`}
          >
            {task.title}
          </span>
          <span className="text-sm text-tasks-sub" suppressHydrationWarning>
            {startText(task.startAt)}
          </span>
          {task.description.trim() !== "" && (
            <span className="line-clamp-2 text-xs text-tasks-sub">
              {task.description}
            </span>
          )}
          {isDue && (
            <span className="text-xs font-medium text-danger">
              Waktunya sudah tiba
            </span>
          )}
        </button>
        {isDue && (
          <button
            onClick={() => void setDone(task, true)}
            className="rounded-[10px] bg-danger px-3 py-1.5 text-xs font-semibold text-background"
          >
            Matikan
          </button>
        )}
        <button
          onClick={() => {
            if (window.confirm(`Hapus tugas "${task.title}"?`)) {
              void run(() => deleteTask(task.id));
            }
          }}
          aria-label={`Hapus tugas ${task.title}`}
          title="Hapus tugas"
          className="flex size-8 shrink-0 items-center justify-center rounded-full text-tasks-sub hover:text-danger"
        >
          <TrashIcon width={18} height={18} />
        </button>
      </li>
    );
  }

  return (
    <div className="flex w-full flex-1 flex-col gap-5 p-6 lg:p-8">
      <h1 className="text-2xl font-semibold">Tugas</h1>

      {/* Sinkron khusus tugas: mengambil daftar terbaru dari server. */}
      <SyncBar
        isSyncing={tasks.isFetching}
        isError={tasks.isError}
        lastSyncedAt={tasks.dataUpdatedAt}
        onSync={() => void tasks.refetch()}
      />

      {notificationPermission === "default" && (
        <div className="flex flex-wrap items-center gap-3 rounded-[14px] bg-primary-soft px-4 py-3 text-sm text-on-primary-soft">
          <span className="flex-1">
            Izinkan notifikasi supaya alarm tugas juga muncul sebagai
            notifikasi browser.
          </span>
          <button
            onClick={() =>
              void Notification.requestPermission().then(setNotificationPermission)
            }
            className="font-semibold"
          >
            Izinkan notifikasi
          </button>
        </div>
      )}

      <form onSubmit={handleCreate} className="flex max-w-3xl flex-wrap gap-2">
        <input
          aria-label="Nama tugas baru"
          placeholder="Nama tugas baru"
          maxLength={255}
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          className="min-w-48 flex-1 rounded-[14px] bg-surface px-4 py-3 outline-none placeholder:text-muted focus:outline-2 focus:outline-primary"
        />
        <input
          type="datetime-local"
          aria-label="Waktu mulai"
          value={startAt || (now > 0 ? defaultStart(new Date(now)) : "")}
          onChange={(event) => setStartAt(event.target.value)}
          suppressHydrationWarning
          className="rounded-[14px] bg-surface px-4 py-3 outline-none focus:outline-2 focus:outline-primary"
        />
        <button
          type="submit"
          disabled={title.trim() === "" || isCreating}
          className="rounded-[14px] bg-primary px-5 py-3 font-semibold text-on-primary disabled:opacity-40"
        >
          Buat
        </button>
      </form>
      <p className="-mt-3 text-xs text-muted">
        Alarm berbunyi di tab ini saat waktu mulainya tiba, selama Manote
        terbuka di browser. Di iPhone, alarm berbunyi setelah tugasnya
        disinkronkan ke sana.
      </p>

      {tasks.isPending && <Spinner />}

      {tasks.isError && (
        <p role="alert" className="text-sm text-danger">
          {tasks.error.message}
        </p>
      )}

      {tasks.data?.length === 0 && (
        <div className="flex flex-1 flex-col items-center justify-center gap-2 text-center">
          <h2 className="text-lg font-semibold">Buat tugas pertama Anda</h2>
          <p className="text-muted">
            Tiap tugas punya waktu mulai, dan alarm berbunyi saat waktunya tiba.
          </p>
        </div>
      )}

      {pending.length > 0 && (
        <ul className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
          {pending.map(renderTask)}
        </ul>
      )}

      {done.length > 0 && (
        <>
          <h2 className="text-sm font-semibold text-muted">Selesai</h2>
          <ul className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
            {done.map(renderTask)}
          </ul>
        </>
      )}

      {editing && (
        <TaskDialog
          key={editing.id}
          task={editing}
          onClose={() => setEditing(null)}
          onSave={(newTitle, newDescription, newStartAt) =>
            run(() =>
              updateTask(editing.id, {
                title: newTitle,
                description: newDescription,
                startAt: newStartAt,
                done: editing.done,
              }),
            )
          }
        />
      )}
    </div>
  );
}

// Dialog ubah tugas: nama, keterangan, dan waktu mulai.
function TaskDialog({
  task,
  onSave,
  onClose,
}: {
  task: TaskItem;
  onSave: (title: string, description: string, startAt: string) => Promise<void>;
  onClose: () => void;
}) {
  const [title, setTitle] = useState(task.title);
  const [description, setDescription] = useState(task.description);
  const [startAt, setStartAt] = useState(toInputValue(new Date(task.startAt)));

  return (
    <div
      className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4"
      onClick={onClose}
    >
      <form
        role="dialog"
        aria-label="Ubah tugas"
        onClick={(event) => event.stopPropagation()}
        onSubmit={(event) => {
          event.preventDefault();
          void onSave(title, description, new Date(startAt).toISOString()).then(onClose);
        }}
        className="flex w-full max-w-md flex-col gap-4 rounded-[20px] bg-background p-5"
      >
        <h2 className="text-lg font-semibold">Ubah tugas</h2>
        <input
          aria-label="Nama tugas"
          required
          maxLength={255}
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          className="rounded-[14px] bg-surface px-4 py-3 outline-none"
        />
        <textarea
          aria-label="Keterangan"
          placeholder="Keterangan (opsional)"
          value={description}
          onChange={(event) => setDescription(event.target.value)}
          className="min-h-24 resize-none rounded-[14px] bg-surface p-3 text-sm outline-none placeholder:text-muted"
        />
        <label className="flex items-center justify-between gap-3 text-sm">
          Mulai
          <input
            type="datetime-local"
            required
            value={startAt}
            onChange={(event) => setStartAt(event.target.value)}
            className="rounded-[10px] bg-surface px-3 py-2"
          />
        </label>
        <div className="flex justify-end gap-2">
          <button
            type="button"
            onClick={onClose}
            className="rounded-[14px] px-4 py-2.5 text-sm font-medium text-muted"
          >
            Batal
          </button>
          <button
            type="submit"
            disabled={title.trim() === ""}
            className="rounded-[14px] bg-primary px-5 py-2.5 text-sm font-semibold text-on-primary disabled:opacity-40"
          >
            Simpan
          </button>
        </div>
      </form>
    </div>
  );
}
