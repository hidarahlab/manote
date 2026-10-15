import SwiftUI

struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @State private var viewModel = LoginViewModel()
    @State private var isPasswordVisible = false

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                LogoMark()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Manote")
                        .font(Theme.Fonts.brand)
                    Text("Meja kerja di saku Anda.")
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, Theme.Spacing.small)

                field(systemImage: "person") {
                    TextField("User ID atau email", text: $viewModel.username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                field(systemImage: "lock") {
                    Group {
                        if isPasswordVisible {
                            TextField("Password", text: $viewModel.password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Password", text: $viewModel.password)
                        }
                    }
                    .textContentType(.password)

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(isPasswordVisible ? "Sembunyikan password" : "Tampilkan password")
                }

                if let notice = session.notice, viewModel.errorMessage == nil {
                    Text(notice)
                        .font(.footnote)
                        .foregroundStyle(Theme.Colors.onPrimarySoft)
                        .padding(Theme.Spacing.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            Theme.Colors.primarySoft,
                            in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                        )
                }

                if let errorMessage = viewModel.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(Theme.Colors.danger)
                }

                Button {
                    Task {
                        if let user = await viewModel.login() {
                            session.didLogIn(user)
                        }
                    }
                } label: {
                    Text("Masuk")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(Theme.Colors.onPrimary)
                        .background(
                            Theme.Colors.primary.opacity(viewModel.canSubmit ? 1 : 0.4),
                            in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                        )
                }
                .disabled(!viewModel.canSubmit)
                .padding(.top, Theme.Spacing.small)
            }
            .padding(Theme.Spacing.xLarge)
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
            .padding(.top, 72)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Colors.background)
        .loadingOverlay(viewModel.isLoading, text: "Masuk…")
    }

    private func field<Content: View>(
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: Theme.Spacing.medium) {
            Image(systemName: systemImage)
                .foregroundStyle(Theme.Colors.primary)
                .frame(width: 20)
            content()
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, 14)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
    }
}

#Preview {
    LoginView()
        .environment(SessionStore())
}
