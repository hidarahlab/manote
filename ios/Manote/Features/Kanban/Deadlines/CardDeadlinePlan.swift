import Foundation

/// Satu pengingat tenggat kartu yang harus muncul pada waktu tertentu.
struct CardDeadlineFire: Equatable {
    let cardId: UUID
    let title: String
    let boardName: String
    let deadlineAt: Date
    let date: Date
    /// Urutan alarm 10 menitan (0 = satu jam sebelum tenggat); `nil` untuk notifikasi.
    let alarmSlot: Int?

    /// Penanda isi, supaya pengingat yang tidak berubah tidak dijadwalkan ulang.
    var signature: String {
        "\(date.timeIntervalSince1970)|\(deadlineAt.timeIntervalSince1970)|\(title)|\(boardName)"
    }
}

/// Aturan pengingat tenggat untuk kartu yang belum sampai Done:
/// - pada hari tenggat, paling awal pukul 08.00, notifikasi tiap 1 jam dihitung mundur dari jam
///   tenggat, yang terakhir 2 jam sebelum tenggat (tenggat 18.47: 08.47, 09.47, ... 16.47);
/// - mulai 1 jam sebelum tenggat, notifikasi dan alarm tiap 10 menit sampai waktu tenggat.
enum CardDeadlinePlan {
    static let firstHour = 8
    static let hour: TimeInterval = 60 * 60
    static let alarmWindow: TimeInterval = hour
    static let alarmInterval: TimeInterval = 10 * 60

    /// Jumlah pengingat yang dijadwalkan sekaligus dibatasi, karena iOS hanya menyimpan 64
    /// notifikasi tertunda untuk seluruh aplikasi. Yang paling dekat didahulukan; sisanya
    /// dijadwalkan saat aplikasi dibuka lagi.
    static let maxNotifications = 40
    static let maxAlarms = 14

    static func make(
        cards: [Card], boardNames: [UUID: String], now: Date = .now, calendar: Calendar = .current
    ) -> (notifications: [CardDeadlineFire], alarms: [CardDeadlineFire]) {
        var notifications: [CardDeadlineFire] = []
        var alarms: [CardDeadlineFire] = []

        for card in cards where card.status != .done && !card.isDeleted {
            guard let deadlineAt = card.deadlineAt, deadlineAt > now else { continue }
            let fire = { (date: Date, slot: Int?) in
                CardDeadlineFire(
                    cardId: card.id, title: card.title, boardName: boardNames[card.boardId] ?? "",
                    deadlineAt: deadlineAt, date: date, alarmSlot: slot
                )
            }
            let alarmStart = deadlineAt.addingTimeInterval(-alarmWindow)

            // Notifikasi per jam pada hari tenggat: 2 jam sebelum tenggat, 3 jam, dan seterusnya,
            // mundur sampai batas pukul 08.00.
            let day = calendar.startOfDay(for: deadlineAt)
            if let earliest = calendar.date(bySettingHour: firstHour, minute: 0, second: 0, of: day) {
                var date = deadlineAt.addingTimeInterval(-2 * hour)
                while date >= earliest {
                    if date > now { notifications.append(fire(date, nil)) }
                    date = date.addingTimeInterval(-hour)
                }
            }

            // Satu jam terakhir: notifikasi dan alarm tiap 10 menit sampai tepat waktu tenggat.
            for slot in 0...Int(alarmWindow / alarmInterval) {
                let date = alarmStart.addingTimeInterval(Double(slot) * alarmInterval)
                guard date > now else { continue }
                notifications.append(fire(date, nil))
                alarms.append(fire(date, slot))
            }
        }

        let nearest = { (fires: [CardDeadlineFire], limit: Int) in
            Array(fires.sorted { ($0.date, $0.cardId.uuidString) < ($1.date, $1.cardId.uuidString) }.prefix(limit))
        }
        return (nearest(notifications, maxNotifications), nearest(alarms, maxAlarms))
    }

    /// "Tenggat hari ini pukul 15.00 · Nama kerjaan"
    static func bodyText(for fire: CardDeadlineFire) -> String {
        let time = fire.deadlineAt.formatted(.dateTime.hour().minute().locale(Locale(identifier: "id_ID")))
        let text = "Tenggat hari ini pukul \(time)"
        return fire.boardName.isEmpty ? text : "\(text) · \(fire.boardName)"
    }

    /// ID alarm per kartu dan urutan, selalu sama untuk pasangan yang sama, supaya alarm yang
    /// sudah terpasang bisa dikenali dan dibatalkan.
    static func alarmId(cardId: UUID, slot: Int) -> UUID {
        var bytes = cardId.uuid
        bytes.15 ^= UInt8(truncatingIfNeeded: slot + 1)
        bytes.14 ^= 0xA5
        return UUID(uuid: bytes)
    }
}
