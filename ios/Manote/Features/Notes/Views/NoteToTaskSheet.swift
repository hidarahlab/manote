import SwiftUI

/// Bottom sheet "Jadikan tugas": memilih kapan tugasnya mulai sebelum catatan dipindahkan.
struct NoteToTaskSheet: View {
    let onConfirm: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startAt: Date

    init(suggestedStart: Date, onConfirm: @escaping (Date) -> Void) {
        self.onConfirm = onConfirm
        _startAt = State(initialValue: suggestedStart)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Mulai", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "id_ID"))
                } footer: {
                    Text("Catatan dipindahkan menjadi tugas, lalu dihapus dari Catatan. Judulnya menjadi nama tugas, isinya menjadi keterangan, dan alarm berbunyi pada waktu mulai.")
                }
            }
            .navigationTitle("Jadikan tugas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Jadikan tugas") {
                        dismiss()
                        onConfirm(startAt)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
