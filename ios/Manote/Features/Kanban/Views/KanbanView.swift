import SwiftUI

/// Tab Kerjaan: daftar kerjaan. Mengetuk satu kerjaan membuka papan kanbannya.
struct KanbanView: View {
    @State private var viewModel = BoardsViewModel()
    @State private var boardToDelete: Board?
    @State private var isNamingBoard = false

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            content
                .background(Theme.Colors.background)
            .loadingOverlay(viewModel.isLoadingFirstSync)
            .navigationTitle(AppFeature.kanban.title)
            .toolbar {
                Button {
                    isNamingBoard = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Buat kerjaan")
            }
            .alert("Kerjaan baru", isPresented: $isNamingBoard) {
                TextField("Nama kerjaan", text: $viewModel.newBoardName)
                Button("Buat") {
                    viewModel.create()
                }
                Button("Batal", role: .cancel) {
                    viewModel.newBoardName = ""
                }
            } message: {
                Text("Satu kerjaan adalah satu papan kanban.")
            }
            .navigationDestination(for: Board.self) { board in
                BoardView(board: board)
            }
            .confirmationDialog(
                deleteTitle,
                isPresented: Binding(get: { boardToDelete != nil }, set: { if !$0 { boardToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Hapus", role: .destructive) {
                    if let board = boardToDelete {
                        viewModel.delete(board)
                    }
                }
            }
            .task {
                await viewModel.syncIfNeverSynced()
            }
        }
    }

    private var deleteTitle: String {
        guard let board = boardToDelete else { return "" }
        let cardCount = viewModel.cardCount(for: board)
        return cardCount > 0
            ? "Hapus kerjaan “\(board.name)” beserta \(cardCount) kartunya?"
            : "Hapus kerjaan “\(board.name)”?"
    }

    private var syncBar: some View {
        SyncStatusBar(status: viewModel.syncStatus) {
            await viewModel.syncNow()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.boards.isEmpty {
            VStack(spacing: 0) {
                syncBar
                    .padding(.horizontal, Theme.Spacing.large)
                    .padding(.top, Theme.Spacing.small)
                emptyState
            }
        } else {
            list
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Buat kerjaan pertama Anda", systemImage: AppFeature.kanban.systemImage)
        } description: {
            Text("Satu kerjaan adalah satu papan kanban: Backlog, Todo, In Progress, Review, dan Done.")
        } actions: {
            Button("Buat kerjaan") {
                isNamingBoard = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var list: some View {
        List {
            Section {
                syncBar.listHeaderRow()
            }
            .listSectionSpacing(Theme.Spacing.large)

            ForEach(viewModel.boards) { board in
                NavigationLink(value: board) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(board.name)
                            .font(Theme.Fonts.cardTitle)
                            .foregroundStyle(AppFeature.kanban.titleColor)
                            .lineLimit(1)
                        HStack(spacing: Theme.Spacing.small) {
                            Text(viewModel.progressText(for: board))
                            if board.isDirty {
                                Label("Belum tersinkron", systemImage: "arrow.triangle.2.circlepath")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(AppFeature.kanban.subtitleColor)
                    }
                    .padding(.vertical, 4)
                    // Garis pemisah selalu mulai dari tepi kiri isi baris.
                    .alignmentGuide(.listRowSeparatorLeading) { dimensions in dimensions[.leading] }
                }
                .listRowBackground(AppFeature.kanban.background)
                .swipeActions {
                    Button(role: .destructive) {
                        boardToDelete = board
                    } label: {
                        Label("Hapus", systemImage: "trash")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .contentMargins(.top, Theme.Spacing.small, for: .scrollContent)
    }
}
