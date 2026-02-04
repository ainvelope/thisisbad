import SwiftUI
import SwiftData

// MARK: - Edit Item View
// A form for editing an existing food item.
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
    @State private var sizeQuantity: String = ""
    @State private var sizeUnit: SizeUnit = .none
    @State private var remainingAmount: Double = 1.0

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

                // Size field (optional): quantity + unit dropdown
                HStack(spacing: 12) {
                    TextField("Qty", text: $sizeQuantity)
                        .keyboardType(.decimalPad)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Size quantity, optional")

                    Picker("Unit", selection: $sizeUnit) {
                        ForEach(SizeUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Size unit, optional")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Size optional: quantity and unit")

                // Amount remaining toggle
                Picker("Amount Remaining", selection: $remainingAmount) {
                    Text("Low").tag(0.0)
                    Text("Full").tag(1.0)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Amount remaining, \(remainingAmount >= 0.5 ? "Full" : "Low")")
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
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
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
            let parsed = SizeUnit.parse(item.size)
            sizeQuantity = parsed.quantity
            sizeUnit = parsed.unit
            remainingAmount = item.remainingAmount < 0.5 ? 0 : 1
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
        item.remainingAmount = remainingAmount

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        item.notes = trimmedNotes.isEmpty ? nil : trimmedNotes

        item.size = SizeUnit.format(quantity: sizeQuantity, unit: sizeUnit)

        // Reschedule notifications with the new expiration date
        notificationService.cancelNotification(for: item)
        notificationService.scheduleNotifications(for: item)

        // SwiftData automatically saves changes
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
