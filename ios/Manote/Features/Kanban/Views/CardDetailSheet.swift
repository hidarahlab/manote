import SwiftUI

/// Detail kartu: ubah judul dan deskripsi, pindah kolom, atau hapus.
struct CardDetailSheet: View {
    let card: Card
    let viewModel: BoardViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var status: CardStatus
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var isConfirmingDelete = false

    init(card: Card, viewModel: BoardViewModel) {
        self.card = card
        self.viewModel = viewModel
        _title = State(initialValue: card.title)
        _description = State(initialValue: card.description)
        _status = State(initialValue: card.status)
        _hasDeadline = State(initialValue: card.deadlineAt != nil)
        _deadline = State(initialValue: card.deadlineAt ?? Self.defaultDeadline())
    }

    private var deadlineAt: Date? { hasDeadline ? deadline : nil }

    /// Besok pada jam yang sama, sebagai nilai awal saat tenggat baru dinyalakan.
    private static func defaultDeadline(now: Date = .now) -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Judul") {
                    TextField("Judul kartu", text: $title, axis: .vertical)
                }
                Section("Deskripsi") {
                    TextField("Deskripsi", text: $description, axis: .vertical)
                        .lineLimit(4...12)
                }
                Section {
                    Picker("Kolom", selection: $status) {
                        ForEach(CardStatus.allCases) { status in
                            Text(status.label).tag(status)
                        }
                    }
                }
                Section {
                    Toggle("Tenggat", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Waktu", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                            .environment(\.locale, Locale(identifier: "id_ID"))
                    }
                } footer: {
                    Text("Kartu berwarna merah saat tenggat tinggal 1 hari, kuning saat tinggal 2 hari, dan hijau jika masih lebih lama.")
                }
                Section {
                    Button("Hapus kartu", role: .destructive) {
                        isConfirmingDelete = true
                    }
                }
            }
            .navigationTitle("Kartu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .confirmationDialog("Hapus kartu ini?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Hapus", role: .destructive) {
                    viewModel.delete(card)
                    dismiss()
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        if trimmedTitle != card.title || description != card.description || deadlineAt != card.deadlineAt {
            viewModel.update(card, title: trimmedTitle, description: description, deadlineAt: deadlineAt)
        }
        if status != card.status {
            viewModel.move(card, to: status)
        }
        dismiss()
    }
}
