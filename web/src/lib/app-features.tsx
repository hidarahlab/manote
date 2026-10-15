import type { ComponentType, SVGProps } from "react";
import { AlarmIcon, KanbanIcon, NoteIcon } from "@/components/icons";

export type AppFeatureKey = "notes" | "kanban" | "tasks";

export type AppFeature = {
  key: AppFeatureKey;
  title: string;
  href: string;
  Icon: ComponentType<SVGProps<SVGSVGElement>>;
  // Kelas ditulis utuh supaya terbaca oleh Tailwind.
  backgroundClass: string;
  titleClass: string;
  subtitleClass: string;
};

export const appFeatures: AppFeature[] = [
  {
    key: "notes",
    title: "Catatan",
    href: "/notes",
    Icon: NoteIcon,
    backgroundClass: "bg-notes-bg",
    titleClass: "text-notes-title",
    subtitleClass: "text-notes-sub",
  },
  {
    key: "kanban",
    title: "Kerjaan",
    href: "/kanban",
    Icon: KanbanIcon,
    backgroundClass: "bg-kanban-bg",
    titleClass: "text-kanban-title",
    subtitleClass: "text-kanban-sub",
  },
  {
    key: "tasks",
    title: "Tugas",
    href: "/tasks",
    Icon: AlarmIcon,
    backgroundClass: "bg-tasks-bg",
    titleClass: "text-tasks-title",
    subtitleClass: "text-tasks-sub",
  },
];
