import SwiftUI

/// Menutup layar dengan indikator memuat dan menahan input selama permintaan ke server berjalan.
private struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let text: String

    func body(content: Content) -> some View {
        content
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()
                        VStack(spacing: Theme.Spacing.medium) {
                            ProgressView()
                                .controlSize(.large)
                                .tint(Theme.Colors.primary)
                            Text(text)
                                .font(.subheadline)
                        }
                        .padding(Theme.Spacing.xLarge)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    }
                    .transition(.opacity)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isModal)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

extension View {
    func loadingOverlay(_ isLoading: Bool, text: String = "Memuat…") -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, text: text))
    }
}

#Preview {
    Text("Isi layar")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .loadingOverlay(true)
}
