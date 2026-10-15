import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    enum State: Equatable {
        case loading
        case loggedOut
        case loggedIn(User)
    }

    private(set) var state: State = .loading
    /// Pesan untuk layar login, misalnya saat sesi berakhir atau server tidak terjangkau.
    private(set) var notice: String?
    private let repository = AuthRepository()
    private let defaults = UserDefaults.standard
    private static let cachedUserKey = "session.user"

    func restore() async {
        guard repository.hasToken else {
            state = .loggedOut
            return
        }

        // Pengguna yang pernah login langsung masuk ke data di perangkat, walau server tidak
        // terjangkau. Sesinya diperiksa ke server sambil jalan.
        if let cachedUser {
            enter(cachedUser)
        }
        do {
            enter(try await handlingErrorsLocally { try await repository.currentUser() })
        } catch let error as APIError where error.isUnauthorized {
            expire()
        } catch {
            if cachedUser == nil {
                // Token tetap disimpan: begitu server terjangkau lagi, sesi bisa dipulihkan.
                notice = error.localizedDescription
                state = .loggedOut
            }
        }
    }

    func didLogIn(_ user: User) {
        notice = nil
        enter(user)
    }

    func logout() {
        leave()
        notice = nil
    }

    /// Server menolak token yang tersimpan.
    func expire() {
        leave()
        notice = "Sesi berakhir. Silakan login lagi."
    }

    private func enter(_ user: User) {
        if case .loggedIn(let current) = state, current.userId == user.userId {
            // Sudah masuk sebagai pengguna ini; cukup perbarui datanya.
        } else {
            NotesSyncService.shared.start(userId: user.userId)
            KanbanSyncService.shared.start(userId: user.userId)
            TasksSyncService.shared.start(userId: user.userId)
        }
        cachedUser = user
        state = .loggedIn(user)
    }

    /// Catatan tetap tersimpan di perangkat untuk login berikutnya oleh pengguna yang sama.
    private func leave() {
        repository.logout()
        cachedUser = nil
        NotesSyncService.shared.stop()
        KanbanSyncService.shared.stop()
        TasksSyncService.shared.stop()
        // Setelah logout tidak ada lagi pengingat tenggat kartu.
        Task { await CardDeadlineScheduler.shared.reconcile(cards: [], boards: []) }
        WidgetSnapshotWriter.update(isLoggedIn: false)
        state = .loggedOut
    }

    /// Pengguna yang terakhir login di perangkat ini. Dipakai tombol alarm, yang bisa berjalan
    /// saat aplikasi tidak sedang dibuka.
    static var cachedUserId: String? {
        UserDefaults.standard.data(forKey: cachedUserKey)
            .flatMap { try? JSONDecoder().decode(User.self, from: $0) }?
            .userId
    }

    private var cachedUser: User? {
        get {
            defaults.data(forKey: Self.cachedUserKey).flatMap { try? JSONDecoder().decode(User.self, from: $0) }
        }
        set {
            defaults.set(newValue.flatMap { try? JSONEncoder().encode($0) }, forKey: Self.cachedUserKey)
        }
    }
}
