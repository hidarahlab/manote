import SwiftUI

struct NoteEditorView: View {
    private enum Field {
        case title
        case content
    }

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: NoteEditorViewModel
    @State private var isConfirmingDelete = false
    @State private var reminderTarget: ReminderTarget?
    @State private var isPickingBoard = false
    @State private var isMakingTask = false
    @FocusState private var focusedField: Field?

    init(note: Note?) {
        _viewModel = State(initialValue: NoteEditorViewModel(note: note))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            TextField("Judul", text: $viewModel.title)
                .font(Theme.Fonts.title)
                .focused($focusedField, equals: .title)
                .submitLabel(.next)
                .onSubmit { focusedField = .content }
                .padding(.horizontal, Theme.Spacing.large)

            TextEditor(text: $viewModel.content)
                .focused($focusedField, equals: .content)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, Theme.Spacing.large - 5)
                .overlay(alignment: .topLeading) {
                    if viewModel.content.isEmpty {
                        Text("Tulis catatan…")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, Theme.Spacing.large)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding(.top, Theme.Spacing.small)
        .background(Theme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.status.label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                // Memindahkan catatan ke fitur lain.
                Menu {
                    Button {
                        isPickingBoard = true
                    } label: {
                        Label("Jadikan kerjaan", systemImage: AppFeature.kanban.systemImage)
                    }
                    Button {
                        isMakingTask = true
                    } label: {
                        Label("Jadikan tugas", systemImage: AppFeature.tasks.systemImage)
                    }
                } label: {
                    Image(systemName: "arrow.up.forward.square")
                }
                .disabled(viewModel.title.isEmpty && viewModel.content.isEmpty)
                .accessibilityLabel("Pindahkan catatan")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    reminderTarget = viewModel.saveNow()
                } label: {
                    Image(systemName: viewModel.reminderAt == nil ? "bell" : "bell.badge.fill")
                }
                .disabled(viewModel.title.isEmpty && viewModel.content.isEmpty)
                .accessibilityLabel(viewModel.reminderAt == nil ? "Atur pengingat" : "Ubah pengingat")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Hapus catatan")
            }
        }
        .confirmationDialog("Hapus catatan ini?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Hapus", role: .destructive) {
                Task {
                    await viewModel.delete()
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $isPickingBoard) {
            BoardPickerSheet(
                title: "Jadikan kerjaan di…",
                message: "Catatan dipindahkan menjadi kartu di Backlog, lalu dihapus dari Catatan. Pengingatnya menjadi tenggat kartu."
            ) { board in
                Task {
                    if await viewModel.assign(to: board) { dismiss() }
                }
            }
        }
        .sheet(isPresented: $isMakingTask) {
            NoteToTaskSheet(suggestedStart: viewModel.suggestedTaskStart) { startAt in
                Task {
                    if await viewModel.convertToTask(startAt: startAt) { dismiss() }
                }
            }
        }
        .sheet(item: $reminderTarget) { target in
            ReminderSheet(target: target) { date in
                viewModel.reminderAt = date
            }
        }
        .onAppear {
            viewModel.reopen()
            if viewModel.isNew { focusedField = .title }
        }
        .onDisappear {
            Task { await viewModel.close() }
        }
    }
}
