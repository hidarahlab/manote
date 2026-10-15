import SwiftUI

/// Form tugas: nama dan kapan harus mulai. Alarm berbunyi pada waktu mulainya.
struct TaskEditorSheet: View {
    let task: TaskItem?
    let onSave: (String, String, Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var details: String
    @State private var startAt: Date
    @FocusState private var isTitleFocused: Bool

    init(task: TaskItem?, onSave: @escaping (String, String, Date) -> Void) {
        self.task = task
        self.onSave = onSave
        _title = State(initialValue: task?.title ?? "")
        _details = State(initialValue: task?.details ?? "")
        _startAt = State(initialValue: task?.startAt ?? Self.defaultStart())
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Jam bulat berikutnya.
    private static func defaultStart(now: Date = .now) -> Date {
        let calendar = Calendar.current
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        return calendar.date(bySetting: .minute, value: 0, of: nextHour) ?? nextHour
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Nama tugas") {
                    TextField("Nama tugas", text: $title, axis: .vertical)
                        .focused($isTitleFocused)
                }
                Section("Keterangan") {
                    TextField("Keterangan (opsional)", text: $details, axis: .vertical)
                        .lineLimit(3...10)
                }
                Section {
                    DatePicker("Mulai", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "id_ID"))
                } footer: {
                    Text("Alarm berbunyi pada waktu ini. Mematikan alarm menandai tugas selesai; “Tunda 5 menit” membunyikannya lagi 5 menit kemudian.")
                }
            }
            .navigationTitle(task == nil ? "Tugas baru" : "Ubah tugas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        onSave(title, details, startAt)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if task == nil { isTitleFocused = true }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
