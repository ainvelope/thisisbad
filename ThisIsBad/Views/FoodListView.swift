import SwiftUI
import SwiftData

// MARK: - Sort Option
enum FoodListSortOption: String, CaseIterable {
    case name = "Name"
    case expirationDate = "Expiration Date"
    case remainingAmount = "Remaining Amount"
}

// MARK: - Food List View
// Displays a list of food items for a specific storage location.
struct FoodListView: View {
    // MARK: - Properties

    // The storage location to filter items by
    let location: StorageLocation

    // @Query automatically fetches FoodItem data from SwiftData.
    @Query(sort: \FoodItem.expirationDate) private var allItems: [FoodItem]

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationService: NotificationService

    @State private var sortOption: FoodListSortOption = .expirationDate
    @State private var isEditing = false
    @State private var selectedIds: Set<UUID> = []
    @State private var showingDeleteAllAlert = false

    // MARK: - Computed Properties

    // Filter items to show only active items in the current location
    private var filteredItems: [FoodItem] {
        allItems.filter { item in
            item.location == location && item.status == .active
        }
    }

    // Sort filtered items by the selected option
    private var sortedItems: [FoodItem] {
        switch sortOption {
        case .name:
            filteredItems.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .expirationDate:
            filteredItems.sorted { $0.expirationDate < $1.expirationDate }
        case .remainingAmount:
            filteredItems.sorted { $0.remainingAmount < $1.remainingAmount }
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if filteredItems.isEmpty {
                ContentUnavailableView {
                    Label("No Items", systemImage: location.iconName)
                } description: {
                    Text("Tap the + button to add food to your \(location.rawValue.lowercased()).")
                }
            } else {
                List(selection: $selectedIds) {
                    ForEach(sortedItems) { item in
                        if isEditing {
                            FoodItemRow(item: item)
                                .tag(item.id)
                                .deleteDisabled(true)
                        } else {
                            NavigationLink {
                                EditItemView(item: item)
                            } label: {
                                FoodItemRow(item: item)
                            }
                            .tag(item.id)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                    if !isEditing {
                        selectedIds.removeAll()
                    }
                }
                .disabled(filteredItems.isEmpty)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(FoodListSortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                }
                .disabled(filteredItems.isEmpty)
            }

            if isEditing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            deleteSelectedItems()
                        } label: {
                            Label("Delete Selected", systemImage: "trash")
                        }
                        .disabled(selectedIds.isEmpty)

                        Button(role: .destructive) {
                            showingDeleteAllAlert = true
                        } label: {
                            Label("Delete All", systemImage: "trash.fill")
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .alert("Delete All Items?", isPresented: $showingDeleteAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                deleteAllItems()
                isEditing = false
                selectedIds.removeAll()
            }
        } message: {
            Text("This will permanently remove all \(filteredItems.count) items from your \(location.rawValue.lowercased()).")
        }
    }

    // MARK: - Methods

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = sortedItems[index]
            notificationService.cancelNotification(for: item)
            modelContext.delete(item)
        }
    }

    private func deleteSelectedItems() {
        for item in sortedItems where selectedIds.contains(item.id) {
            notificationService.cancelNotification(for: item)
            modelContext.delete(item)
        }
        selectedIds.removeAll()
    }

    private func deleteAllItems() {
        for item in filteredItems {
            notificationService.cancelNotification(for: item)
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
