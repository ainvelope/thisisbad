import SwiftUI
import SwiftData

// MARK: - Edit Item View
// A form for editing an existing food item or marking it as used/discarded.
struct EditItemView: View {
    // MARK: - Properties

    // The item being edited (passed from the list view)
    // @Bindable allows us to create bindings to the item's properties
    @Bindable var item: FoodItem

    // Access the presentation mode to dismiss this view
    @Environment(\.dismiss) private var dismiss

    // Access the SwiftData model context for delete operations
    @Environment(\.modelContext) private var modelContext

    // Access the notification service
    @EnvironmentObject private var notificationService: NotificationService

    // MARK: Form State
    // These hold the edited values (initialized from the item)

    @State private var name: String = ""
    @State private var location: StorageLocation = .fridge
    @State private var expirationDate: Date = Date()
    @State private var notes: String = ""

    // Tracks whether we've attempted to submit (for validation)
    @State private var hasAttemptedSave = false

    // Confirmation alert for delete action
    @State private var showingDeleteAlert = false

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        Form {
            // MARK: Item Details Section
            Section {
                TextField("Item Name", text: $name)
                    .textInputAutocapitalization(.words)

                if hasAttemptedSave && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Please enter an item name")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Picker("Location", selection: $location) {
                    ForEach(StorageLocation.allCases) { loc in
                        Label(loc.rawValue, systemImage: loc.iconName)
                            .tag(loc)
                    }
                }

                DatePicker(
                    "Expiration Date",
                    selection: $expirationDate,
                    displayedComponents: .date
                )
            } header: {
                Text("Item Details")
            }

            // MARK: Notes Section
            Section {
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("Additional Info")
            }

            // MARK: Quick Actions Section
            Section {
                // Mark as Used button
                Button {
                    markAsUsed()
                } label: {
                    Label("Mark as Used", systemImage: "checkmark.circle")
                }
                .tint(.green)

                // Mark as Discarded button
                Button {
                    markAsDiscarded()
                } label: {
                    Label("Mark as Discarded", systemImage: "trash")
                }
                .tint(.orange)
            } header: {
                Text("Quick Actions")
            } footer: {
                Text("Marking an item removes it from your active list.")
            }

            // MARK: Delete Section
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Item", systemImage: "trash.fill")
                }
            }
        }
        .navigationTitle("Edit Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .fontWeight(.semibold)
            }
        }
        // Load current item values when view appears
        .onAppear {
            name = item.name
            location = item.location
            expirationDate = item.expirationDate
            notes = item.notes ?? ""
        }
        // Delete confirmation alert
        .alert("Delete Item?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("This will permanently remove \"\(item.name)\" from your tracker.")
        }
    }

    // MARK: - Methods

    // Save the edited values back to the item
    private func saveChanges() {
        hasAttemptedSave = true

        guard isFormValid else { return }

        // Update the item's properties
        item.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        item.location = location
        item.expirationDate = expirationDate

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        item.notes = trimmedNotes.isEmpty ? nil : trimmedNotes

        // Reschedule notifications with the new expiration date
        notificationService.cancelNotification(for: item)
        notificationService.scheduleNotifications(for: item)

        // SwiftData automatically saves changes
        dismiss()
    }

    // Mark the item as used (consumed)
    private func markAsUsed() {
        item.status = .used
        notificationService.cancelNotification(for: item)
        dismiss()
    }

    // Mark the item as discarded (thrown away)
    private func markAsDiscarded() {
        item.status = .discarded
        notificationService.cancelNotification(for: item)
        dismiss()
    }

    // Permanently delete the item
    private func deleteItem() {
        notificationService.cancelNotification(for: item)
        modelContext.delete(item)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        EditItemView(item: FoodItem(
            name: "Milk",
            location: .fridge,
            expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
            notes: "2% organic"
        ))
    }
    .modelContainer(for: FoodItem.self, inMemory: true)
    .environmentObject(NotificationService())
}
