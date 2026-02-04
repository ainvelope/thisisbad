import SwiftUI
import SwiftData

// MARK: - Grocery List View
// Shopping list - add items to buy and check them off when purchased.
struct GroceryListView: View {
    // MARK: - Properties

    @Query(sort: \GroceryItem.dateAdded) private var items: [GroceryItem]
    @Query private var foodItems: [FoodItem]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingAddItem = false

    // MARK: - Computed Properties

    private var incompleteItems: [GroceryItem] {
        items.filter { !$0.isCompleted }
    }

    private var completedItems: [GroceryItem] {
        items.filter { $0.isCompleted }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("No Items", systemImage: "cart")
                    } description: {
                        Text("Add items you need to buy.")
                    }
                } else {
                    List {
                        ForEach(incompleteItems) { item in
                            GroceryRow(item: item, onToggle: { item.isCompleted.toggle() })
                        }
                        .onDelete(perform: deleteIncomplete)

                        ForEach(completedItems) { item in
                            GroceryRow(item: item, onToggle: { item.isCompleted.toggle() })
                        }
                        .onDelete(perform: deleteCompleted)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Grocery List")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add item")
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddGroceryItemView()
            }
            .onAppear {
                syncExpiringItemsToGroceryList()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    syncExpiringItemsToGroceryList()
                }
            }
        }
    }

    // MARK: - Methods

    /// Syncs food items to the grocery list:
    /// - Adds items that are expiring soon (≤3 days), already expired, or running low (< 30%)
    /// - Removes items that no longer meet criteria (> 30% remaining AND > 3 days until expiration)
    /// Only considers active food items.
    private func syncExpiringItemsToGroceryList() {
        // Step 1: Add items that need to be on the grocery list
        let itemsToAdd = foodItems.filter { item in
            item.status == .active &&
            (item.expirationStatus == .warning || 
             item.expirationStatus == .expired ||
             item.remainingAmount < 0.3)
        }

        let existingNames = Set(items.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() })
        var addedNames = existingNames

        for food in itemsToAdd {
            let name = food.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, !addedNames.contains(name.lowercased()) else { continue }
            modelContext.insert(GroceryItem(name: name))
            addedNames.insert(name.lowercased())
        }

        // Step 2: Remove items that no longer meet the criteria
        // Build a map of active food items by name (lowercased)
        let activeFoodByName = Dictionary(
            foodItems
                .filter { $0.status == .active }
                .map { ($0.name.trimmingCharacters(in: .whitespaces).lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // Check each grocery item to see if it should be removed
        for groceryItem in items where !groceryItem.isCompleted {
            let groceryName = groceryItem.name.trimmingCharacters(in: .whitespaces).lowercased()
            
            // If there's a matching active food item
            if let foodItem = activeFoodByName[groceryName] {
                // Remove from grocery list if it's now healthy (> 30% AND more than 3 days)
                let isHealthy = foodItem.remainingAmount >= 0.3 && foodItem.expirationStatus == .safe
                if isHealthy {
                    modelContext.delete(groceryItem)
                }
            }
        }
    }

    private func deleteIncomplete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(incompleteItems[index])
        }
    }

    private func deleteCompleted(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(completedItems[index])
        }
    }
}

// MARK: - Grocery Row
private struct GroceryRow: View {
    let item: GroceryItem
    let onToggle: () -> Void

    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isCompleted ? .green : .secondary)

                Text(item.name)
                    .strikethrough(item.isCompleted, color: .secondary)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Grocery Item View
private struct AddGroceryItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Item name", text: $name)
                    .textInputAutocapitalization(.words)
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private func addItem() {
        guard isFormValid else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        modelContext.insert(GroceryItem(name: trimmed))
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    GroceryListView()
        .modelContainer(for: [FoodItem.self, GroceryItem.self], inMemory: true)
}
