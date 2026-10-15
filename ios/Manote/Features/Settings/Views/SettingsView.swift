import SwiftUI

/// Tab Pengaturan. Untuk sekarang isinya hanya pilihan tema.
struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Tema", selection: selection) {
                        ForEach(AppTheme.allCases) { theme in
                            Label(theme.label, systemImage: theme.systemImage).tag(theme)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Tema")
                } footer: {
                    Text("Berlaku di iPhone ini. Sebelum dipilih, tema mengikuti pengaturan iPhone.")
                }
                .listRowBackground(Theme.Colors.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background)
            .navigationTitle("Pengaturan")
        }
    }

    private var selection: Binding<AppTheme> {
        Binding(
            get: { viewModel.selectedTheme(system: colorScheme) },
            set: { viewModel.select($0) }
        )
    }
}

#Preview {
    SettingsView()
}
