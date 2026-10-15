import SwiftUI

struct NotesView: View {
    private enum Route: Hashable {
        case new
        case edit(Note)
    }

    @State private var viewModel = NotesViewModel()
    @State private var path: [Route] = []
    private let router = ReminderRouter.shared

    var body: some View {
        NavigationStack(path: $path) {
            content
                .background(Theme.Colors.background)
            .loadingOverlay(viewModel.isLoadingFirstSync)
            .navigationTitle(AppFeature.notes.title)
            .toolbar {
                Button {
                    path.append(.new)
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Buat catatan")
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .new:
                    NoteEditorView(note: nil)
                case .edit(let note):
                    NoteEditorView(note: note)
                }
            }
            .task {
                await viewModel.syncIfNeverSynced()
                openPendingNote()
            }
            .onChange(of: router.pendingNoteId) {
                openPendingNote()
            }
        }
    }

    /// Buka catatan yang notifikasi pengingatnya baru diketuk.
    private func openPendingNote() {
        guard let noteId = router.pendingNoteId,
              let note = viewModel.notes.first(where: { $0.id == noteId }) else { return }
        router.pendingNoteId = nil
        path = [.edit(note)]
    }

    private var syncBar: some View {
        SyncStatusBar(status: viewModel.syncStatus) {
            await viewModel.syncNow()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.notes.isEmpty {
            VStack(spacing: 0) {
                syncBar
                    .padding(.horizontal, Theme.Spacing.large)
                    .padding(.top, Theme.Spacing.small)
                ContentUnavailableView {
                    Label("Tulis catatan pertama Anda", systemImage: AppFeature.notes.systemImage)
                } description: {
                    Text("Catat pekerjaan, ide, atau hasil rapat supaya tidak lupa.")
                } actions: {
                    Button("Buat catatan") {
                        path.append(.new)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } else {
            list
        }
    }

    private var list: some View {
        List {
            Section {
                syncBar.listHeaderRow()
            }
            .listSectionSpacing(Theme.Spacing.large)

            ForEach(viewModel.notes) { note in
                NavigationLink(value: Route.edit(note)) {
                    row(for: note)
                }
                .listRowBackground(AppFeature.notes.background)
                .swipeActions {
                    Button(role: .destructive) {
                        Task { await viewModel.delete(note) }
                    } label: {
                        Label("Hapus", systemImage: "trash")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .contentMargins(.top, Theme.Spacing.small, for: .scrollContent)
    }

    private func row(for note: Note) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.displayTitle)
                .font(Theme.Fonts.cardTitle)
                .foregroundStyle(AppFeature.notes.titleColor)
                .lineLimit(1)
            if !note.preview.isEmpty {
                Text(note.preview)
                    .font(.subheadline)
                    .foregroundStyle(AppFeature.notes.subtitleColor)
                    .lineLimit(2)
            }
            HStack(spacing: Theme.Spacing.small) {
                Text(note.updatedText())
                if let reminderText = note.reminderText {
                    Label(reminderText, systemImage: "bell.fill")
                }
                if note.isDirty {
                    Label("Belum tersinkron", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            .font(.caption)
            .foregroundStyle(AppFeature.notes.subtitleColor)
        }
        .padding(.vertical, 4)
        // Garis pemisah selalu mulai dari tepi kiri isi baris. Tanpa ini, iOS menggesernya ke
        // teks milik ikon (lonceng pengingat, tanda belum tersinkron) kalau baris memuatnya.
        .alignmentGuide(.listRowSeparatorLeading) { dimensions in dimensions[.leading] }
    }
}

#Preview {
    NotesView()
}
