import SwiftUI
import SwiftData

// MARK: - Add Item View
// A form for adding a new food item to the tracker.
struct AddItemView: View {
    // MARK: - Properties

    // The default location (based on which tab was selected)
    let defaultLocation: StorageLocation

    /// Called when save completes in tab mode (e.g. to switch back to Home).
    /// When nil, the view dismisses itself (sheet mode).
    var onSaveComplete: (() -> Void)? = nil

    /// Called when cancel is tapped in tab mode (e.g. to switch back to Home).
    /// When nil, the view dismisses itself (sheet mode).
    var onCancel: (() -> Void)? = nil

    // Access the presentation mode to dismiss this view
    @Environment(\.dismiss) private var dismiss

    // Access the SwiftData model context to save new items
    @Environment(\.modelContext) private var modelContext

    // Access the notification service to schedule notifications
    @EnvironmentObject private var notificationService: NotificationService

    // MARK: Form State
    // These @State properties hold the form input values

    @State private var name: String = ""
    @State private var location: StorageLocation = .fridge
    @State private var expirationDate: Date = Date()
    @State private var notes: String = ""
    @State private var sizeQuantity: String = ""
    @State private var sizeUnit: SizeUnit = .none
    @State private var remainingAmount: Double = 1.0

    // Tracks whether we've attempted to submit (for validation display)
    @State private var hasAttemptedSave = false

    // MARK: - Computed Properties

    // Check if the form is valid (name is required)
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Item Details Section
                Section {
                    // Item name field
                    TextField("Item Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Item name, required")

                    // Show validation error if name is empty after attempted save
                    if hasAttemptedSave && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Please enter an item name")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    // Location picker
                    Picker("Location", selection: $location) {
                        ForEach(StorageLocation.allCases) { loc in
                            Label(loc.rawValue, systemImage: loc.iconName)
                                .tag(loc)
                        }
                    }

                    // Expiration date picker
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

                // MARK: Notes Section (Optional)
                Section {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Additional Info")
                } footer: {
                    Text("Add notes like \"opened\", \"homemade\", or \"half remaining\".")
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Done button above numeric keyboard
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                // Cancel button
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if let onCancel {
                            onCancel()
                        } else {
                            dismiss()
                        }
                    }
                }

                // Save button
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .fontWeight(.semibold)
                }
            }
            // Set default location when view appears
            .onAppear {
                location = defaultLocation
            }
        }
    }

    // MARK: - Methods

    // Save the new item to SwiftData
    private func saveItem() {
        // Mark that we've attempted to save (for validation display)
        hasAttemptedSave = true

        // Check if form is valid
        guard isFormValid else { return }

        // Create the new food item
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let sizeString = SizeUnit.format(quantity: sizeQuantity, unit: sizeUnit)

        let newItem = FoodItem(
            name: trimmedName,
            location: location,
            expirationDate: expirationDate,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            remainingAmount: remainingAmount,
            size: sizeString
        )

        // Insert the item into SwiftData (this automatically saves it)
        modelContext.insert(newItem)

        // Schedule notifications for this item
        notificationService.scheduleNotifications(for: newItem)

        // Dismiss or switch tab based on presentation context
        if let onSaveComplete {
            onSaveComplete()
        } else {
            dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    AddItemView(defaultLocation: .fridge)
        .modelContainer(for: FoodItem.self, inMemory: true)
        .environmentObject(NotificationService())
}
