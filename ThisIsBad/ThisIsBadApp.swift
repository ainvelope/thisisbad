import SwiftUI
import SwiftData

// MARK: - App Entry Point
// @main marks this as the starting point of the app.
// The App protocol defines the structure of a SwiftUI application.
@main
struct ThisIsBadApp: App {
    // MARK: - Properties

    // NotificationService is created once and shared throughout the app
    // @StateObject means SwiftUI manages this object's lifecycle
    @StateObject private var notificationService = NotificationService()

    // MARK: - Body

    // The 'body' property defines the app's scene (window) structure
    var body: some Scene {
        // WindowGroup is the standard scene for iOS apps
        WindowGroup {
            // ContentView is our main view
            ContentView()
                // Make the notification service available to all child views
                .environmentObject(notificationService)
                // Request notification permission when the app first appears
                .task {
                    await notificationService.requestPermission()
                }
        }
        // Configure SwiftData with our FoodItem model
        // This creates the database and makes it available throughout the app
        .modelContainer(for: [FoodItem.self, GroceryItem.self])
    }
}
