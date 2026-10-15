import SwiftUI

/// Bottom sheet pengingat: form tanggal dan jam. Dibuka dari tombol lonceng di editor catatan.
struct ReminderSheet: View {
    /// Dipanggil saat pengingat tersimpan (dengan waktunya) atau dihapus (`nil`).
    let onChanged: (Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ReminderViewModel

    init(target: ReminderTarget, onChanged: @escaping (Date?) -> Void) {
        _viewModel = State(initialValue: ReminderViewModel(target: target))
        self.onChanged = onChanged
    }

    var body: some View {
        Group {
            if viewModel.warning != nil {
                savedWithWarning
            } else {
                form
            }
        }
        .padding(Theme.Spacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.Colors.background)
        .loadingOverlay(viewModel.isSaving, text: "Menyimpan…")
        .toastHost()
        .presentationDetents(viewModel.warning == nil ? [.large] : [.height(300)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isSaving)
    }

    private var form: some View {
        @Bindable var viewModel = viewModel

        return VStack(spacing: Theme.Spacing.large) {
            header(title: "Atur pengingat", systemImage: "bell")

            DatePicker(
                "Tanggal dan jam",
                selection: $viewModel.date,
                in: viewModel.minimumDate...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .environment(\.locale, Locale(identifier: "id_ID"))

            Text("Masuk ke Kalender, dan notifikasi dengan suara muncul pada waktunya.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            primaryButton("Simpan pengingat") {
                Task {
                    onChanged(await viewModel.save())
                    if viewModel.warning == nil { dismiss() }
                }
            }
            .disabled(viewModel.isSaving)

            if viewModel.hasExistingReminder {
                Button("Hapus pengingat", role: .destructive) {
                    Task {
                        await viewModel.remove()
                        onChanged(nil)
                        dismiss()
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
    }

    private var savedWithWarning: some View {
        VStack(spacing: Theme.Spacing.large) {
            header(title: "Pengingat tersimpan", systemImage: "bell.badge")

            Text(viewModel.warning ?? "")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            primaryButton("Mengerti") { dismiss() }
        }
    }

    private func header(title: String, systemImage: String) -> some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Theme.Colors.onPrimarySoft)
                .frame(width: 56, height: 56)
                .background(Theme.Colors.primarySoft, in: Circle())
            Text(title)
                .font(Theme.Fonts.title)
        }
        .padding(.top, Theme.Spacing.small)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(Theme.Colors.onPrimary)
                .background(Theme.Colors.primary, in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
        }
    }
}
