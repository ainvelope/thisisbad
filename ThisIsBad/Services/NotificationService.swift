import Foundation
import UserNotifications
import Combine

// MARK: - Notification Service
// Handles all push notification logic: requesting permission,
// scheduling notifications, and canceling them.
//
// This class is an ObservableObject so it can be used with @EnvironmentObject
// and @StateObject throughout the app.
final class NotificationService: ObservableObject {
    // MARK: - Published Properties
    // These properties automatically update any views observing this service

    // Whether the user has granted notification permission
    @Published var isAuthorized: Bool = false

    // User preference: days before expiration to send first notification
    @Published var daysBeforeNotification: Int {
        didSet {
            // Save to UserDefaults when changed
            UserDefaults.standard.set(daysBeforeNotification, forKey: "daysBeforeNotification")
        }
    }

    // User preference: whether to notify on the actual expiration day
    @Published var notifyOnExpirationDay: Bool {
        didSet {
            UserDefaults.standard.set(notifyOnExpirationDay, forKey: "notifyOnExpirationDay")
        }
    }

    // MARK: - Private Properties

    // Reference to the notification center
    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Initializer

    init() {
        // Load saved preferences from UserDefaults, with defaults
        self.daysBeforeNotification = UserDefaults.standard.object(forKey: "daysBeforeNotification") as? Int ?? 3
        self.notifyOnExpirationDay = UserDefaults.standard.object(forKey: "notifyOnExpirationDay") as? Bool ?? true

        // Check current authorization status
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Public Methods

    /// Request permission from the user to send notifications
    /// - Returns: true if permission was granted, false otherwise
    @discardableResult
    func requestPermission() async -> Bool {
        do {
            // Request permission for alerts, sounds, and badges
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            isAuthorized = granted
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }

    /// Check the current notification authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    /// Schedule notifications for a food item based on user preferences
    /// - Parameter item: The food item to schedule notifications for
    func scheduleNotifications(for item: FoodItem) {
        // Only schedule if we have permission
        guard isAuthorized else { return }

        // Only schedule for active items
        guard item.status == .active else { return }

        // Schedule "expiring soon" notification (X days before)
        if daysBeforeNotification > 0 {
            scheduleNotification(
                for: item,
                daysBefore: daysBeforeNotification,
                identifier: "\(item.id.uuidString)-warning"
            )
        }

        // Schedule "expires today" notification
        if notifyOnExpirationDay {
            scheduleNotification(
                for: item,
                daysBefore: 0,
                identifier: "\(item.id.uuidString)-expiry"
            )
        }
    }

    /// Cancel all notifications for a specific item
    /// - Parameter item: The food item to cancel notifications for
    func cancelNotification(for item: FoodItem) {
        let identifiers = [
            "\(item.id.uuidString)-warning",
            "\(item.id.uuidString)-expiry"
        ]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Cancel all pending notifications (useful for testing or reset)
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Private Methods

    /// Schedule a single notification for an item
    private func scheduleNotification(for item: FoodItem, daysBefore: Int, identifier: String) {
        // Calculate the notification date
        guard let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBefore,
            to: item.expirationDate
        ) else { return }

        // Don't schedule notifications in the past
        guard notificationDate > Date() else { return }

        // Create the notification content
        let content = UNMutableNotificationContent()
        content.sound = .default

        if daysBefore == 0 {
            // Expiration day notification
            content.title = "Food Expires Today!"
            content.body = "\(item.name) expires today. Use it or lose it!"
        } else if daysBefore == 1 {
            // One day before
            content.title = "Food Expiring Tomorrow"
            content.body = "\(item.name) expires tomorrow."
        } else {
            // Multiple days before
            content.title = "Food Expiring Soon"
            content.body = "\(item.name) expires in \(daysBefore) days."
        }

        // Create the trigger (time-based)
        // We schedule for 9:00 AM on the notification date
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: notificationDate
        )
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        // Create the request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        // Schedule the notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
