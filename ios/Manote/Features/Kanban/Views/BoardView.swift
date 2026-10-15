import SwiftUI

/// Papan kanban satu kerjaan: lima kolom yang digeser ke samping.
struct BoardView: View {
    @State private var viewModel: BoardViewModel
    @State private var openCard: Card?
    private let title: String

    init(board: Board) {
        title = board.name
        _viewModel = State(initialValue: BoardViewModel(board: board))
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            SyncStatusBar(status: viewModel.syncStatus) {
                await viewModel.syncNow()
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.top, Theme.Spacing.small)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Theme.Spacing.medium) {
                    ForEach(CardStatus.allCases) { status in
                        BoardColumn(
                            status: status,
                            cards: viewModel.cards(in: status),
                            onOpen: { openCard = $0 },
                            onMove: { card, target in viewModel.move(card, to: target) },
                            onAdd: { viewModel.addCard(title: $0, to: status) }
                        )
                        .containerRelativeFrame(.horizontal) { width, _ in min(width * 0.82, 340) }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.bottom, Theme.Spacing.large)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.Colors.background)
        .navigationTitle(viewModel.name ?? title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $openCard) { card in
            CardDetailSheet(card: card, viewModel: viewModel)
        }
    }
}

private struct BoardColumn: View {
    let status: CardStatus
    let cards: [Card]
    let onOpen: (Card) -> Void
    let onMove: (Card, CardStatus) -> Void
    let onAdd: (String) -> Bool

    @State private var newTitle = ""
    @FocusState private var isAdding: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack {
                Text(status.label)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(cards.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            ScrollView {
                VStack(spacing: Theme.Spacing.small) {
                    ForEach(cards) { card in
                        cardRow(card)
                    }

                    // Enter menambah kartu dan kolom ketik tetap terbuka untuk kartu berikutnya.
                    TextField("+ Tambah kartu", text: $newTitle)
                        .focused($isAdding)
                        .submitLabel(.done)
                        .onSubmit {
                            if onAdd(newTitle) {
                                newTitle = ""
                                isAdding = true
                            }
                        }
                        .font(.subheadline)
                        .padding(Theme.Spacing.medium)
                }
            }
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private func cardRow(_ card: Card) -> some View {
        // Warna kartu mengikuti sisa waktu ke tenggat.
        let level = card.deadlineLevel()
        let colors = DeadlineColors(level: level)

        return HStack(alignment: .top, spacing: Theme.Spacing.small) {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(colors.title)
                    .multilineTextAlignment(.leading)
                if level == .done {
                    // Kartu selesai hanya menampilkan judul dan waktu selesainya.
                    Text(card.doneText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(colors.detail)
                } else {
                    cardDetails(card, colors: colors)
                }
            }
            Spacer(minLength: 0)

            Menu {
                Section("Pindahkan ke") {
                    ForEach(CardStatus.allCases.filter { $0 != card.status }) { target in
                        Button(target.label) { onMove(card, target) }
                    }
                }
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.footnote)
                    .foregroundStyle(colors.accent)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Pindahkan kartu")
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.background, in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { onOpen(card) }
    }

    @ViewBuilder
    private func cardDetails(_ card: Card, colors: DeadlineColors) -> some View {
        if !card.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(card.description)
                .font(.caption)
                .foregroundStyle(colors.detail)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        if let deadlineText = card.deadlineText {
            Text(deadlineText)
                .font(.caption.weight(.medium))
                .foregroundStyle(colors.detail)
                .padding(.top, 2)
        }
        if card.isDirty {
            Label("Belum tersinkron", systemImage: "arrow.triangle.2.circlepath")
                .font(.caption2)
                .foregroundStyle(colors.detail)
        }
    }
}

/// Warna kartu per tingkat tenggat: abu-abu, hijau muda, kuning, merah, hitam (lewat tenggat),
/// dan hijau (selesai).
private struct DeadlineColors {
    let background: Color
    var title: Color = .primary
    let detail: Color
    /// Warna tombol di atas kartu.
    var accent: Color = Theme.Colors.primary

    init(level: DeadlineLevel) {
        switch level {
        case .none:
            background = Theme.Colors.background
            detail = .secondary
        case .safe:
            background = Color(light: 0xE1F5EE, dark: 0x04342C)
            detail = Color(light: 0x0F6E56, dark: 0x5DCAA5)
        case .soon:
            background = Color(light: 0xFAEEDA, dark: 0x412402)
            detail = Color(light: 0x854F0B, dark: 0xEF9F27)
        case .urgent:
            background = Color(light: 0xFCEBEB, dark: 0x501313)
            detail = Color(light: 0xA32D2D, dark: 0xF09595)
        case .overdue:
            background = .black
            title = .white
            detail = Color(light: 0xC9C9CF, dark: 0xC9C9CF)
            accent = .white
        case .done:
            background = Color(light: 0x0F6E56, dark: 0x0F6E56)
            title = .white
            detail = Color(light: 0xC8EFE2, dark: 0xC8EFE2)
            accent = .white
        }
    }
}
