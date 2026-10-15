import SwiftUI

/// Tab Tugas: daftar tugas dengan waktu mulainya. Alarm tugas bisa dimatikan dari sini.
struct TasksView: View {
    private enum Editor: Identifiable {
        case new
        case edit(TaskItem)

        var id: String {
            switch self {
            case .new: "new"
            case .edit(let task): task.id.uuidString
            }
        }

        var task: TaskItem? {
            if case .edit(let task) = self { return task }
            return nil
        }
    }

    @State private var viewModel = TasksViewModel()
    @State private var editor: Editor?

    var body: some View {
        NavigationStack {
            content
                .background(Theme.Colors.background)
            .loadingOverlay(viewModel.isLoadingFirstSync)
            .navigationTitle(AppFeature.tasks.title)
            .toolbar {
                Button {
                    editor = .new
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Buat tugas")
            }
            .sheet(item: $editor) { editor in
                TaskEditorSheet(task: editor.task) { title, details, startAt in
                    viewModel.save(id: editor.task?.id, title: title, details: details, startAt: startAt)
                }
            }
            .task {
                await viewModel.syncIfNeverSynced()
            }
        }
    }

    private var syncBar: some View {
        VStack(spacing: Theme.Spacing.small) {
            SyncStatusBar(status: viewModel.syncStatus) {
                await viewModel.syncNow()
            }
            if viewModel.isAlarmDenied {
                Label(
                    "Izin alarm ditolak, jadi tugas hanya memunculkan notifikasi. Aktifkan di Pengaturan > Manote.",
                    systemImage: "alarm"
                )
                .font(.footnote)
                .foregroundStyle(Theme.Colors.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isEmpty {
            VStack(spacing: 0) {
                syncBar
                    .padding(.horizontal, Theme.Spacing.large)
                    .padding(.top, Theme.Spacing.small)
                ContentUnavailableView {
                    Label("Buat tugas pertama Anda", systemImage: AppFeature.tasks.systemImage)
                } description: {
                    Text("Tiap tugas punya waktu mulai, dan alarm berbunyi saat waktunya tiba.")
                } actions: {
                    Button("Buat tugas") {
                        editor = .new
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } else {
            // Diperbarui berkala supaya tanda "alarm berbunyi" muncul tepat waktu.
            TimelineView(.periodic(from: .now, by: 15)) { context in
                List {
                    Section {
                        syncBar.listHeaderRow()
                    }
                    .listSectionSpacing(Theme.Spacing.large)

                    if !viewModel.pendingTasks.isEmpty {
                        Section {
                            ForEach(viewModel.pendingTasks) { task in
                                row(for: task, now: context.date)
                            }
                        }
                    }
                    if !viewModel.doneTasks.isEmpty {
                        Section("Selesai") {
                            ForEach(viewModel.doneTasks) { task in
                                row(for: task, now: context.date)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .contentMargins(.top, Theme.Spacing.small, for: .scrollContent)
            }
        }
    }

    private func row(for task: TaskItem, now: Date) -> some View {
        let isDue = task.isDue(now: now)

        return HStack(alignment: .top, spacing: Theme.Spacing.medium) {
            Button {
                viewModel.setDone(task, !task.isDone)
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(AppFeature.tasks.titleColor)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(task.isDone ? "Tandai belum selesai" : "Tandai selesai")

            Button {
                editor = .edit(task)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(Theme.Fonts.cardTitle)
                        .foregroundStyle(AppFeature.tasks.titleColor)
                        .strikethrough(task.isDone)
                        .multilineTextAlignment(.leading)
                    Text(task.startText)
                        .font(.subheadline)
                        .foregroundStyle(AppFeature.tasks.subtitleColor)
                    if !task.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(task.details)
                            .font(.caption)
                            .foregroundStyle(AppFeature.tasks.subtitleColor)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    HStack(spacing: Theme.Spacing.small) {
                        if isDue {
                            Label("Alarm berbunyi", systemImage: "alarm.waves.left.and.right")
                                .foregroundStyle(Theme.Colors.danger)
                        }
                        if task.isDirty {
                            Label("Belum tersinkron", systemImage: "arrow.triangle.2.circlepath")
                                .foregroundStyle(AppFeature.tasks.subtitleColor)
                        }
                    }
                    .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)

            if isDue {
                Button("Matikan") {
                    viewModel.setDone(task, true)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.Colors.danger)
                .font(.footnote.weight(.semibold))
            }
        }
        .padding(.vertical, 4)
        // Garis pemisah selalu mulai dari tepi kiri isi baris.
        .alignmentGuide(.listRowSeparatorLeading) { dimensions in dimensions[.leading] }
        .listRowBackground(AppFeature.tasks.background)
        .swipeActions {
            Button(role: .destructive) {
                viewModel.delete(task)
            } label: {
                Label("Hapus", systemImage: "trash")
            }
        }
    }
}

#Preview {
    TasksView()
}
