import Foundation

/// Penyimpanan tugas di perangkat, satu file per pengguna.
@MainActor
final class TasksStore {
    private struct State: Codable {
        var tasks: [TaskItem] = []
        var cursor: String?
        var lastSyncedAt: Date?
    }

    private var state: State
    private let fileURL: URL

    init(userId: String, directory: URL = NotesStore.defaultDirectory) {
        fileURL = directory.appending(path: "tasks-\(userId).json")
        if let data = try? Data(contentsOf: fileURL), let saved = try? JSONDecoder().decode(State.self, from: data) {
            state = saved
        } else {
            state = State()
        }
    }

    // MARK: - Baca

    /// Tugas yang belum selesai, urut dari yang paling dekat waktu mulainya.
    var pendingTasks: [TaskItem] {
        state.tasks.filter { !$0.isDeleted && !$0.isDone }.sorted { $0.startAt < $1.startAt }
    }

    /// Tugas yang sudah selesai, yang baru selesai di atas.
    var doneTasks: [TaskItem] {
        state.tasks.filter { !$0.isDeleted && $0.isDone }.sorted { ($0.doneAt ?? .distantPast) > ($1.doneAt ?? .distantPast) }
    }

    /// Perubahan yang belum sampai ke server.
    var unsyncedTasks: [TaskItem] { state.tasks.filter(\.isDirty) }

    var cursor: String? { state.cursor }

    var lastSyncedAt: Date? { state.lastSyncedAt }

    func task(id: UUID) -> TaskItem? {
        state.tasks.first { $0.id == id && !$0.isDeleted }
    }

    // MARK: - Ubah di perangkat

    /// Membuat tugas baru (`id` kosong) atau mengubah yang ada.
    @discardableResult
    func save(id: UUID?, title: String, details: String, startAt: Date, now: Date = .now) -> TaskItem {
        if let id, let index = state.tasks.firstIndex(where: { $0.id == id }) {
            state.tasks[index].title = title
            state.tasks[index].details = details
            state.tasks[index].startAt = startAt
            touch(index, now: now)
            return state.tasks[index]
        }
        let task = TaskItem(
            id: id ?? UUID(), serverId: nil, title: title, details: details, startAt: startAt, doneAt: nil,
            createdAt: now, updatedAt: now, isDeleted: false, isDirty: true
        )
        state.tasks.append(task)
        persist()
        return task
    }

    func setDone(id: UUID, _ done: Bool, now: Date = .now) {
        guard let index = state.tasks.firstIndex(where: { $0.id == id }),
              state.tasks[index].isDone != done else { return }
        state.tasks[index].doneAt = done ? now : nil
        touch(index, now: now)
    }

    /// Menandai terhapus; barisnya baru dibuang setelah server diberi tahu.
    func delete(id: UUID, now: Date = .now) {
        guard let index = state.tasks.firstIndex(where: { $0.id == id }) else { return }
        state.tasks[index].isDeleted = true
        touch(index, now: now)
    }

    private func touch(_ index: Int, now: Date) {
        state.tasks[index].updatedAt = now
        state.tasks[index].isDirty = true
        persist()
    }

    // MARK: - Terapkan hasil sinkron

    /// - Parameter pushed: tugas yang dikirim pada sinkron ini, dengan waktu ubahnya saat dikirim.
    func apply(_ response: TaskSyncResponse, pushed: [UUID: Date], now: Date = .now) {
        for serverTask in response.tasks {
            let index = state.tasks.firstIndex { $0.id == serverTask.clientId }

            // Diubah lagi di perangkat setelah dikirim (atau belum sempat dikirim): versi perangkat
            // dipertahankan dan dikirim pada sinkron berikutnya.
            if let index, state.tasks[index].isDirty,
               state.tasks[index].updatedAt > (pushed[serverTask.clientId] ?? .distantPast) {
                state.tasks[index].serverId = serverTask.id
                continue
            }

            if serverTask.deleted {
                if let index { state.tasks.remove(at: index) }
                continue
            }

            let task = TaskItem(
                id: serverTask.clientId, serverId: serverTask.id, title: serverTask.title,
                details: serverTask.description ?? "", startAt: serverTask.startAt, doneAt: serverTask.doneAt, createdAt: serverTask.createdAt,
                updatedAt: serverTask.updatedAt, isDeleted: false, isDirty: false
            )
            if let index {
                state.tasks[index] = task
            } else {
                state.tasks.append(task)
            }
        }

        // Tanda terhapus yang sudah dikirim tidak perlu disimpan lagi.
        state.tasks.removeAll { task in
            task.isDeleted && pushed[task.id] == task.updatedAt
        }

        state.cursor = response.cursor
        state.lastSyncedAt = now
        persist()
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(state).write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Gagal menyimpan tugas ke perangkat: \(error)")
        }
    }
}
