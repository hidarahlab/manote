import SwiftUI

/// Logo Manote: selembar kertas dengan tiga garis berwarna.
struct LogoMark: View {
    var size: CGFloat = 64

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(Color(light: 0x534AB7, dark: 0x534AB7))
            .frame(width: size, height: size)
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.1, style: .continuous)
                    .fill(.white)
                    .padding(size * 0.22)
                    .overlay {
                        VStack(alignment: .leading, spacing: size * 0.075) {
                            line(0xEF9F27, width: 0.36)
                            line(0x1D9E75, width: 0.28)
                            line(0xD85A30, width: 0.20)
                        }
                        .frame(width: size * 0.36, alignment: .leading)
                    }
            }
            .accessibilityHidden(true)
    }

    private func line(_ hex: UInt32, width: CGFloat) -> some View {
        Capsule()
            .fill(Color(light: hex, dark: hex))
            .frame(width: size * width, height: size * 0.065)
    }
}

#Preview {
    LogoMark()
}
