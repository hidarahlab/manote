import SwiftUI

struct RootView: View {
    @State private var session = SessionStore()
    private let appearance = AppearanceStore.shared

    var body: some View {
        Group {
            switch session.state {
            case .loading:
                Theme.Colors.background
                    .ignoresSafeArea()
                    .loadingOverlay(true)
            case .loggedOut:
                LoginView()
            case .loggedIn(let user):
                MainTabView(user: user)
            }
        }
        .tint(Theme.Colors.primary)
        // Tema pilihan dari Pengaturan; `nil` berarti mengikuti iPhone.
        .preferredColorScheme(appearance.theme?.colorScheme)
        .toastHost()
        .environment(session)
        .task {
            await session.restore()
        }
        .onReceive(NotificationCenter.default.publisher(for: .manoteSessionExpired)) { _ in
            if case .loggedIn = session.state {
                session.expire()
            }
        }
    }
}

struct MainTabView: View {
    enum Tab: Hashable {
        case dashboard
        case feature(AppFeature)
        case settings
    }

    let user: User
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: Tab = .dashboard
    private let router = ReminderRouter.shared
    private let notesSync = NotesSyncService.shared
    private let tasksSync = TasksSyncService.shared
    private let kanbanSync = KanbanSyncService.shared

    var body: some View {
        TabView(selection: $selection) {
            DashboardView(user: user) { feature in
                selection = .feature(feature)
            }
            .tabItem { Label("Dashboard", systemImage: "house") }
            .tag(Tab.dashboard)

            NotesView()
                .tabItem { Label(AppFeature.notes.title, systemImage: AppFeature.notes.systemImage) }
                .tag(Tab.feature(.notes))
            KanbanView()
                .tabItem { Label(AppFeature.kanban.title, systemImage: AppFeature.kanban.systemImage) }
                .tag(Tab.feature(.kanban))
            TasksView()
                .tabItem { Label(AppFeature.tasks.title, systemImage: AppFeature.tasks.systemImage) }
                .tag(Tab.feature(.tasks))
            SettingsView()
                .tabItem { Label("Pengaturan", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        // Setelah sinkron, batalkan pengingat di perangkat untuk catatan yang sudah dihapus
        // atau pengingatnya dicabut di tempat lain.
        .onChange(of: notesSync.lastSyncedAt) {
            let withReminder = notesSync.notes.filter { $0.reminderAt != nil }.map(\.id)
            Task { await ReminderScheduler.shared.cancelAll(except: Set(withReminder)) }
        }
        // Daftar tugas berubah (dibuat, selesai, dihapus, atau hasil sinkron): alarm disesuaikan.
        .onChange(of: tasksSync.revision, initial: true) {
            Task { await TaskAlarmScheduler.shared.reconcile(pending: tasksSync.pendingTasks) }
        }
        // Kartu berubah, atau aplikasi dibuka lagi: pengingat tenggat kartu disesuaikan.
        .onChange(of: kanbanSync.cards, initial: true) { reconcileCardDeadlines() }
        .onChange(of: scenePhase) {
            if scenePhase == .active { reconcileCardDeadlines() }
        }
        // Widget layar utama mengikuti data di perangkat.
        .onChange(of: tasksSync.revision, initial: true) { WidgetSnapshotWriter.update() }
        .onChange(of: notesSync.notes.count) { WidgetSnapshotWriter.update() }
        .onChange(of: kanbanSync.cards) { WidgetSnapshotWriter.update() }
        // Widget diketuk: buka tab Tugas.
        .onOpenURL { url in
            if url.scheme == "manote", url.host() == "tasks" {
                selection = .feature(.tasks)
            }
        }
        .onChange(of: router.pendingNoteId, initial: true) {
            if router.pendingNoteId != nil {
                selection = .feature(.notes)
            }
        }
    }

    private func reconcileCardDeadlines() {
        let cards = kanbanSync.cards
        let boards = kanbanSync.boards
        Task { await CardDeadlineScheduler.shared.reconcile(cards: cards, boards: boards) }
    }
}

#Preview {
    RootView()
}
