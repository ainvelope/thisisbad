import SwiftUI

// MARK: - Settings View
// Allows users to configure notification preferences.
struct SettingsView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notificationService: NotificationService

    /// When false, hides the Done button (e.g. when displayed as a tab).
    var showDismissButton: Bool = true

    // Options for "days before" picker
    private let dayOptions = [1, 2, 3, 5, 7]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Notification Settings Section
                Section {
                    // Show current authorization status
                    HStack {
                        Text("Notifications")
                        Spacer()
                        if notificationService.isAuthorized {
                            Label("Enabled", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .labelStyle(.titleAndIcon)
                        } else {
                            Label("Disabled", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .labelStyle(.titleAndIcon)
                        }
                    }

                    // If not authorized, show button to open settings
                    if !notificationService.isAuthorized {
                        Button("Enable in Settings") {
                            openAppSettings()
                        }
                    }
                } header: {
                    Text("Notification Status")
                } footer: {
                    if !notificationService.isAuthorized {
                        Text("Notifications are disabled. Tap above to open Settings and enable them.")
                    }
                }

                // MARK: Notification Preferences Section
                // Only show if notifications are authorized
                if notificationService.isAuthorized {
                    Section {
                        // Days before expiration to notify
                        Picker("Remind me", selection: $notificationService.daysBeforeNotification) {
                            ForEach(dayOptions, id: \.self) { days in
                                if days == 1 {
                                    Text("1 day before").tag(days)
                                } else {
                                    Text("\(days) days before").tag(days)
                                }
                            }
                        }

                        // Toggle for expiration day notification
                        Toggle("Notify on expiration day", isOn: $notificationService.notifyOnExpirationDay)
                    } header: {
                        Text("Reminder Timing")
                    } footer: {
                        Text("You'll receive reminders at 9:00 AM on the scheduled days.")
                    }
                }

                // MARK: About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showDismissButton {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            // Refresh authorization status when view appears
            .task {
                await notificationService.checkAuthorizationStatus()
            }
        }
    }

    // MARK: - Methods

    /// Open the app's settings page in the iOS Settings app
    private func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(NotificationService())
}
