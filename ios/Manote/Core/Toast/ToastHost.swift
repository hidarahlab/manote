import SwiftUI

private struct ToastHost: ViewModifier {
    private let center = ToastCenter.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = center.current {
                    Label(
                        toast.message,
                        systemImage: toast.kind == .error ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
                    )
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, Theme.Spacing.large)
                        .padding(.vertical, Theme.Spacing.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            toast.kind == .error
                                ? Color(light: 0xA32D2D, dark: 0x791F1F)
                                : Color(light: 0x0F6E56, dark: 0x085041),
                            in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                        )
                        .padding(.horizontal, Theme.Spacing.large)
                        .padding(.top, Theme.Spacing.small)
                        .onTapGesture { center.dismiss() }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .id(toast.id)
                        .accessibilityAddTraits(.isStaticText)
                }
            }
            .animation(.spring(duration: 0.3), value: center.current)
    }
}

extension View {
    /// Tempat toast tampil. Pasang di akar aplikasi dan di tiap sheet, karena sheet menutupi akar.
    func toastHost() -> some View {
        modifier(ToastHost())
    }
}
