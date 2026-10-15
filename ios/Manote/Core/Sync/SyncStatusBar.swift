import SwiftUI

/// Baris status sinkron dengan tombol "Sinkronkan". Tiap layar memakainya untuk datanya sendiri.
struct SyncStatusBar: View {
    let status: SyncStatus
    let onSync: () async -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            Group {
                if status.isSyncing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: status.needsAttention ? "exclamationmark.icloud" : "checkmark.icloud")
                }
            }
            .frame(width: 20)

            Text(status.text)
                .lineLimit(1)

            Spacer(minLength: Theme.Spacing.small)

            Button("Sinkronkan") {
                Task { await onSync() }
            }
            .font(.footnote.weight(.semibold))
            // Di dalam daftar, hanya tombolnya yang bisa diketuk, bukan seluruh baris.
            .buttonStyle(.borderless)
            .disabled(status.isSyncing)
        }
        .font(.footnote)
        .foregroundStyle(status.needsAttention ? Theme.Colors.danger : .secondary)
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// Menjadikan view ini baris pembuka sebuah `List`: tanpa latar, tanpa garis, selebar daftar.
    /// Baris sinkron ditaruh di dalam daftar supaya ikut bergerak bersama judul layar.
    func listHeaderRow() -> some View {
        listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

#Preview {
    VStack {
        SyncStatusBar(status: SyncStatus(lastSyncedAt: .now)) {}
        SyncStatusBar(status: SyncStatus(isSyncing: true)) {}
        SyncStatusBar(status: SyncStatus(pendingCount: 3, errorMessage: "x")) {}
    }
    .padding()
}
