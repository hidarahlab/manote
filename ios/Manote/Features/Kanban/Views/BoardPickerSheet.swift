import SwiftUI

/// Bottom sheet untuk memilih kerjaan tujuan, misalnya saat catatan dijadikan kartu.
struct BoardPickerSheet: View {
    let title: String
    /// Penjelasan di bawah daftar tentang apa yang terjadi setelah memilih.
    var message: String?
    let onPick: (Board) -> Void

    @Environment(\.dismiss) private var dismiss
    private let kanban = KanbanSyncService.shared

    var body: some View {
        NavigationStack {
            Group {
                if kanban.boards.isEmpty {
                    ContentUnavailableView(
                        "Belum ada kerjaan",
                        systemImage: AppFeature.kanban.systemImage,
                        description: Text("Buat kerjaan dulu di tab Kerjaan.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(kanban.boards) { board in
                                row(for: board)
                            }
                        } footer: {
                            if let message { Text(message) }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(for board: Board) -> some View {
        Button {
            dismiss()
            onPick(board)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(board.name)
                    .font(Theme.Fonts.cardTitle)
                    .foregroundStyle(AppFeature.kanban.titleColor)
                Text(kanban.progressText(for: board))
                    .font(.subheadline)
                    .foregroundStyle(AppFeature.kanban.subtitleColor)
            }
            .padding(.vertical, 4)
            // Garis pemisah selalu mulai dari tepi kiri isi baris.
            .alignmentGuide(.listRowSeparatorLeading) { dimensions in dimensions[.leading] }
        }
        .listRowBackground(AppFeature.kanban.background)
    }
}
