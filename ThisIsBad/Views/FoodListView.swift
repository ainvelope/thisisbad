import SwiftUI
import SwiftData

// MARK: - Sort Option
// Defines the available sorting options for the food list
enum SortOption: String, CaseIterable, Identifiable {
    case expirationDate = "Expiration Date"
    case name = "Name"
    case dateAdded = "Date Added"
    case manual = "Manual"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .expirationDate: return "calendar"
        case .name: return "textformat.abc"
        case .dateAdded: return "clock"
        case .manual: return "hand.draw"
        }
    }
}

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

    // Current sort option
    @State private var sortOption: SortOption = .expirationDate

    // Whether manual sorting (edit mode) is active
    @State private var isEditMode: Bool = false

    // MARK: - Computed Properties

    // Filter and sort items based on current settings
    private var filteredItems: [FoodItem] {
        let filtered = allItems.filter { item in
            item.location == location && item.status == .active
        }

        switch sortOption {
        case .expirationDate:
            return filtered.sorted { $0.expirationDate < $1.expirationDate }
        case .name:
            return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .dateAdded:
            return filtered.sorted { $0.dateAdded < $1.dateAdded }
        case .manual:
            return filtered.sorted { $0.sortOrder < $1.sortOrder }
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
                if isEditMode && sortOption == .manual {
                    // Use UIKit-based reorderable list for manual sorting
                    ReorderableListView(
                        items: filteredItems,
                        onReorder: { sourceIndex, destinationIndex in
                            reorderItems(from: sourceIndex, to: destinationIndex)
                        },
                        onDelete: { index in
                            deleteItem(at: index)
                        }
                    )
                } else {
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    // Edit button for manual sorting
                    if sortOption == .manual && !filteredItems.isEmpty {
                        Button {
                            withAnimation {
                                isEditMode.toggle()
                            }
                        } label: {
                            Image(systemName: isEditMode ? "checkmark.circle.fill" : "pencil.circle")
                                .font(.title3)
                        }
                        .accessibilityLabel(isEditMode ? "Done editing" : "Edit order")
                    }

                    // Sort menu
                    Menu {
                        ForEach(SortOption.allCases) { option in
                            Button {
                                sortOption = option
                                if option != .manual {
                                    isEditMode = false
                                }
                            } label: {
                                Label {
                                    Text(option.rawValue)
                                } icon: {
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.title3)
                    }
                    .accessibilityLabel("Sort options")
                }
            }
        }
        .onChange(of: sortOption) { oldValue, newValue in
            // When switching to manual sort, initialize sort orders if needed
            if newValue == .manual {
                initializeSortOrdersIfNeeded()
            }
        }
    }

    // MARK: - Methods

    // Initialize sort orders based on current order if not already set
    private func initializeSortOrdersIfNeeded() {
        let items = filteredItems
        var needsUpdate = false

        // Check if all items have sortOrder of 0 (uninitialized)
        for item in items {
            if item.sortOrder != 0 {
                needsUpdate = false
                break
            }
            needsUpdate = true
        }

        if needsUpdate {
            for (index, item) in items.enumerated() {
                item.sortOrder = index
            }
        }
    }

    // Reorder items when dragged in edit mode
    private func reorderItems(from sourceIndex: Int, to destinationIndex: Int) {
        var items = filteredItems

        let movedItem = items.remove(at: sourceIndex)
        items.insert(movedItem, at: destinationIndex)

        // Update sort orders
        for (index, item) in items.enumerated() {
            item.sortOrder = index
        }
    }

    // Delete a single item at the specified index
    private func deleteItem(at index: Int) {
        let item = filteredItems[index]
        notificationService.cancelNotification(for: item)
        modelContext.delete(item)
    }

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
