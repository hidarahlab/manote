import Foundation
import SwiftUI
import UserNotifications
#if canImport(AlarmKit)
import AlarmKit
#endif

/// Menyamakan pengingat tenggat di perangkat dengan kartu kanban (aturannya di `CardDeadlinePlan`).
/// Dijadwalkan oleh iPhone sendiri, jadi tetap muncul tanpa server dan saat aplikasi ditutup.
@MainActor
final class CardDeadlineScheduler {
    static let shared = CardDeadlineScheduler()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    private var isReconciling = false
    private var pendingReconcile: (cards: [Card], boards: [Board])?

    /// Dipanggil setiap kartu berubah dan setiap aplikasi dibuka.
    func reconcile(cards: [Card], boards: [Board]) async {
        // Perubahan beruntun cukup diproses dengan data yang paling akhir.
        guard !isReconciling else {
            pendingReconcile = (cards, boards)
            return
        }
        isReconciling = true
        var current: (cards: [Card], boards: [Board])? = (cards, boards)
        while let input = current {
            pendingReconcile = nil
            await apply(cards: input.cards, boards: input.boards)
            current = pendingReconcile
        }
        isReconciling = false
    }

    private func apply(cards: [Card], boards: [Board]) async {
        let boardNames = Dictionary(uniqueKeysWithValues: boards.map { ($0.id, $0.name) })
        var plan = CardDeadlinePlan.make(cards: cards, boardNames: boardNames)

        // Tanpa izin alarm (atau di iOS lama) tinggal notifikasinya, yang waktunya sama.
        if !plan.alarms.isEmpty, await !requestAlarmAccess() {
            plan.alarms = []
        }

        await applyNotifications(plan.notifications)
        await applyAlarms(plan.alarms)
    }

    // MARK: - Notifikasi

    private func applyNotifications(_ fires: [CardDeadlineFire]) async {
        let wanted = Dictionary(fires.map { (Self.notificationId($0), $0) }) { first, _ in first }
        var scheduled = scheduledNotifications

        let stale = scheduled.keys.filter { wanted[$0]?.signature != scheduled[$0] }
        if !stale.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: stale)
            stale.forEach { scheduled[$0] = nil }
        }

        let missing = wanted.filter { scheduled[$0.key] == nil }
        if !missing.isEmpty,
           (try? await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])) == true {
            for (id, fire) in missing {
                let content = UNMutableNotificationContent()
                content.title = fire.title
                content.body = CardDeadlinePlan.bodyText(for: fire)
                content.sound = .default
                content.userInfo = [Self.cardIdKey: fire.cardId.uuidString]

                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second], from: fire.date
                )
                let request = UNNotificationRequest(
                    identifier: id, content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
                if (try? await notificationCenter.add(request)) != nil {
                    scheduled[id] = fire.signature
                }
            }
        }
        scheduledNotifications = scheduled
    }

    nonisolated static let cardIdKey = "cardId"

    private static func notificationId(_ fire: CardDeadlineFire) -> String {
        "card-\(fire.cardId.uuidString)-\(Int(fire.date.timeIntervalSince1970))"
    }

    private var scheduledNotifications: [String: String] {
        get { defaults.dictionary(forKey: "kanban.deadlines.notifications") as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: "kanban.deadlines.notifications") }
    }

    // MARK: - Alarm (AlarmKit)

    private func requestAlarmAccess() async -> Bool {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return false }
        return (try? await AlarmManager.shared.requestAuthorization()) == .authorized
        #else
        return false
        #endif
    }

    private func applyAlarms(_ fires: [CardDeadlineFire]) async {
        let wanted = Dictionary(
            fires.map { (CardDeadlinePlan.alarmId(cardId: $0.cardId, slot: $0.alarmSlot ?? 0).uuidString, $0) }
        ) { first, _ in first }
        var scheduled = scheduledAlarms

        for key in scheduled.keys where wanted[key]?.signature != scheduled[key] {
            if let id = UUID(uuidString: key) { cancelAlarm(id: id) }
            scheduled[key] = nil
        }
        for (key, fire) in wanted where scheduled[key] == nil {
            guard let id = UUID(uuidString: key), await scheduleAlarm(id: id, fire: fire) else { continue }
            scheduled[key] = fire.signature
        }
        scheduledAlarms = scheduled
    }

    private func scheduleAlarm(id: UUID, fire: CardDeadlineFire) async -> Bool {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return false }
        do {
            try? AlarmManager.shared.cancel(id: id)
            _ = try await AlarmManager.shared.schedule(id: id, configuration: CardAlarmConfiguration.make(fire: fire))
            return true
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    private func cancelAlarm(id: UUID) {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return }
        // `stop` untuk alarm yang sedang berbunyi, `cancel` untuk yang belum.
        try? AlarmManager.shared.stop(id: id)
        try? AlarmManager.shared.cancel(id: id)
        #endif
    }

    private var scheduledAlarms: [String: String] {
        get { defaults.dictionary(forKey: "kanban.deadlines.alarms") as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: "kanban.deadlines.alarms") }
    }
}

#if canImport(AlarmKit)
@available(iOS 26.0, *)
enum CardAlarmConfiguration {
    /// Alarm layar penuh berjudul nama kartu dan jam tenggatnya, dengan tombol Matikan saja.
    /// Mematikannya hanya menghentikan bunyi; alarm berikutnya tetap berbunyi 10 menit kemudian
    /// selama kartunya belum dipindah ke Done.
    static func make(fire: CardDeadlineFire) -> AlarmManager.AlarmConfiguration<TaskAlarmMetadata> {
        let time = fire.deadlineAt.formatted(.dateTime.hour().minute().locale(Locale(identifier: "id_ID")))
        let alertTitle = LocalizedStringResource(stringLiteral: "\(fire.title) · tenggat \(time)")

        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = AlarmPresentation.Alert(title: alertTitle)
        } else {
            alert = AlarmPresentation.Alert(
                title: alertTitle,
                stopButton: AlarmButton(text: "Matikan", textColor: .white, systemImageName: "stop.circle")
            )
        }
        let attributes = AlarmAttributes<TaskAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            tintColor: Color(light: 0x534AB7, dark: 0xAFA9EC)
        )
        return .alarm(schedule: .fixed(fire.date), attributes: attributes)
    }
}
#endif
