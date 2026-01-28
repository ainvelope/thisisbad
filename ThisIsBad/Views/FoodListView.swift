import SwiftUI
import SwiftData

// MARK: - Food List View
// Displays a list of food items for a specific storage location.
struct FoodListView: View {
    // MARK: - Properties

    // The storage location to filter items by
    let location: StorageLocation

    // @Query automatically fetches FoodItem data from SwiftData.
    // The results update automatically when the database changes.
    // We sort by expiration date so items expiring soonest appear first.
    @Query(sort: \FoodItem.expirationDate) private var allItems: [FoodItem]

    // Access the SwiftData model context for delete operations
    @Environment(\.modelContext) private var modelContext

    // Access the notification service to cancel notifications when items are deleted
    @EnvironmentObject private var notificationService: NotificationService

    // MARK: - Computed Properties

    // Filter items to show only active items in the current location
    private var filteredItems: [FoodItem] {
        allItems.filter { item in
            item.location == location && item.status == .active
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if filteredItems.isEmpty {
                // MARK: Empty State
                // Show a friendly message when there are no items
                ContentUnavailableView {
                    Label("No Items", systemImage: location.iconName)
                } description: {
                    Text("Tap the + button to add food to your \(location.rawValue.lowercased()).")
                }
            } else {
                // MARK: Item List
                List {
                    ForEach(filteredItems) { item in
                        // Use NavigationLink for navigation to edit view
                        NavigationLink {
                            EditItemView(item: item)
                        } label: {
                            FoodItemRow(item: item)
                        }
                    }
                    // Enable swipe-to-delete
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Methods

    // Delete items at the specified index positions
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredItems[index]
            // Cancel any scheduled notifications for this item
            notificationService.cancelNotification(for: item)
            // Delete the item from SwiftData
            modelContext.delete(item)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        FoodListView(location: .fridge)
    }
    .modelContainer(for: FoodItem.self, inMemory: true)
    .environmentObject(NotificationService())
}
