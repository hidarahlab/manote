"use client";

import { useEffect, useState } from "react";
import { updateTask, type TaskItem } from "../api/tasks-api";
import { useRefreshTasks, useTasks } from "../hooks/use-tasks";
import { startAlarmSound } from "../lib/alarm-sound";
import { startText } from "../lib/task-text";

// Alarm berbunyi 1 menit. Kalau tidak dimatikan, berbunyi lagi 5 menit kemudian, terus begitu
// sampai dimatikan.
const RING_MS = 60_000;
const QUIET_MS = 5 * 60_000;
const SNOOZE_MS = 5 * 60_000;

// Alarm tugas di web. Hanya bekerja selama Manote terbuka di browser, dan hanya untuk tugas
// yang waktu mulainya tiba setelah halaman dibuka.
export function TaskAlarm() {
  const tasks = useTasks();
  const refresh = useRefreshTasks();
  // Jam hanya dibaca di browser, setelah halaman tampil; 0 berarti belum dibaca.
  const [openedAt, setOpenedAt] = useState(0);
  const [now, setNow] = useState(0);
  const [snoozedUntil, setSnoozedUntil] = useState<Record<number, number>>({});

  useEffect(() => {
    const start = setTimeout(() => {
      setOpenedAt(Date.now());
      setNow(Date.now());
    }, 0);
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => {
      clearTimeout(start);
      clearInterval(timer);
    };
  }, []);

  const startOf = (task: TaskItem) => new Date(task.startAt).getTime();
  const active = (tasks.data ?? []).find(
    (task) =>
      openedAt > 0 &&
      !task.done &&
      startOf(task) >= openedAt &&
      startOf(task) <= now &&
      (snoozedUntil[task.id] ?? 0) <= now,
  );

  const ringStart = active
    ? Math.max(startOf(active), snoozedUntil[active.id] ?? 0)
    : 0;
  const elapsed = now - ringStart;
  const round = Math.floor(elapsed / (RING_MS + QUIET_MS));
  const isRinging = active !== undefined && elapsed % (RING_MS + QUIET_MS) < RING_MS;
  const activeId = active?.id;
  const activeTitle = active?.title;

  useEffect(() => {
    if (!isRinging) return;
    return startAlarmSound();
  }, [isRinging, activeId, round]);

  useEffect(() => {
    if (!isRinging || activeTitle === undefined) return;
    if ("Notification" in window && Notification.permission === "granted") {
      new Notification("Waktunya mulai", { body: activeTitle, tag: `task-${activeId}` });
    }
  }, [isRinging, activeId, activeTitle, round]);

  if (!active) return null;

  // Mematikan alarm menandai tugas selesai.
  async function turnOff(task: TaskItem) {
    try {
      await updateTask(task.id, {
        title: task.title,
        startAt: task.startAt,
        done: true,
      });
    } catch {
      // Toast sudah menampilkan sebabnya.
    }
    await refresh();
  }

  const nextRingIn = Math.ceil(
    (RING_MS + QUIET_MS - (elapsed % (RING_MS + QUIET_MS))) / 60_000,
  );

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div
        role="alertdialog"
        aria-label="Alarm tugas"
        data-ringing={isRinging}
        className="flex w-full max-w-sm flex-col gap-4 rounded-[20px] bg-background p-6 text-center"
      >
        <p className="text-sm font-medium text-danger">
          {isRinging
            ? "Alarm berbunyi"
            : `Alarm berbunyi lagi dalam ${nextRingIn} menit`}
        </p>
        <h2 className="text-2xl font-semibold">{active.title}</h2>
        <p className="text-sm text-muted">{startText(active.startAt)}</p>
        <button
          onClick={() => void turnOff(active)}
          className="rounded-[14px] bg-danger px-5 py-3 font-semibold text-background"
        >
          Matikan
        </button>
        <button
          onClick={() =>
            setSnoozedUntil((current) => ({
              ...current,
              [active.id]: Date.now() + SNOOZE_MS,
            }))
          }
          className="rounded-[14px] bg-surface px-5 py-3 font-medium"
        >
          Tunda 5 menit
        </button>
      </div>
    </div>
  );
}
