import SwiftUI
import SwiftData

// MARK: - Search View
// Search for food items across all storage locations.
struct SearchView: View {
    // MARK: - Properties

    @Query(sort: \FoodItem.expirationDate) private var allItems: [FoodItem]
    @State private var searchText = ""

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationService: NotificationService

    // MARK: - Computed Properties

    private var filteredItems: [FoodItem] {
        let activeItems = allItems.filter { $0.status == .active }
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return activeItems
        }
        let query = searchText.lowercased()
        return activeItems.filter { item in
            item.name.lowercased().contains(query) ||
            (item.notes?.lowercased().contains(query) ?? false)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if filteredItems.isEmpty {
                    if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        ContentUnavailableView {
                            Label("No Items", systemImage: "magnifyingglass")
                        } description: {
                            Text("Add food items from the Add tab, then search for them here.")
                        }
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            NavigationLink {
                                EditItemView(item: item)
                            } label: {
                                FoodItemRow(item: item, showLocation: true)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search food items")
        }
    }

    // MARK: - Methods

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredItems[index]
            notificationService.cancelNotification(for: item)
            modelContext.delete(item)
        }
    }
}

// MARK: - Preview
#Preview {
    SearchView()
        .modelContainer(for: FoodItem.self, inMemory: true)
        .environmentObject(NotificationService())
}
