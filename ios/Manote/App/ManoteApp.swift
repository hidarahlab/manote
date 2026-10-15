import SwiftUI
import UserNotifications

@main
struct ManoteApp: App {
    private let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

//https://ibks-mac-mini.tailfd11c4.ts.net
