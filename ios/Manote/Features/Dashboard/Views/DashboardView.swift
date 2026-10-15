import SwiftUI

struct DashboardView: View {
    let user: User
    let onSelect: (AppFeature) -> Void

    @Environment(SessionStore.self) private var session
    @State private var viewModel: DashboardViewModel

    init(user: User, onSelect: @escaping (AppFeature) -> Void) {
        self.user = user
        self.onSelect = onSelect
        _viewModel = State(initialValue: DashboardViewModel(userId: user.userId))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xLarge) {
                header

                SyncStatusBar(status: viewModel.syncStatus) {
                    await viewModel.sync()
                }

                VStack(spacing: Theme.Spacing.medium) {
                    ForEach(viewModel.features) { feature in
                        Button {
                            onSelect(feature)
                        } label: {
                            card(for: feature)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Theme.Spacing.xLarge)
        }
        .background(Theme.Colors.background)
        .task {
            await viewModel.syncIfNeverSynced()
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Text(viewModel.initials(of: user.fullName))
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.Colors.onPrimarySoft)
                .frame(width: 48, height: 48)
                .background(Theme.Colors.primarySoft, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.greeting())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(user.fullName)
                    .font(Theme.Fonts.title)
            }

            Spacer()

            Button {
                session.logout()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(Theme.Colors.primary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Keluar")
        }
    }

    private func card(for feature: AppFeature) -> some View {
        HStack(spacing: Theme.Spacing.large) {
            Image(systemName: feature.systemImage)
                .font(.title2)
                .foregroundStyle(feature.titleColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(Theme.Fonts.cardTitle)
                    .foregroundStyle(feature.titleColor)
                Text(viewModel.summaryText(for: feature))
                    .font(.subheadline)
                    .foregroundStyle(feature.subtitleColor)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(feature.subtitleColor)
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, minHeight: 84)
        .background(feature.background, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

#Preview {
    DashboardView(
        user: User(userId: "hidarah96", email: "hidarah96@gmail.com", fullName: "Rahmad Hidayat", userType: "USER"),
        onSelect: { _ in }
    )
    .environment(SessionStore())
}
