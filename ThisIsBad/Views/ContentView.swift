import SwiftUI
import SwiftData

// MARK: - Tab
/// Represents the main tabs in the app's tab bar.
enum Tab: String, CaseIterable {
    case home
    case search
    case addItem
    case groceryList
    case settings
}

// MARK: - Content View
// This is the main view of the app, containing the tab bar and navigation.
struct ContentView: View {
    // MARK: - Properties

    // @State creates a mutable property that SwiftUI watches for changes.
    @State private var selectedTab: Tab = .home
    @State private var selectedLocation: StorageLocation = .fridge

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: Home Tab
            NavigationStack {
                VStack(spacing: 0) {
                    FoodListView(location: selectedLocation)
                        .frame(maxHeight: .infinity)

                    // Location Picker: switch between Fridge/Freezer/Pantry
                    Picker("Storage Location", selection: $selectedLocation) {
                        ForEach(StorageLocation.allCases) { location in
                            Label(location.rawValue, systemImage: location.iconName)
                                .tag(location)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                }
                .navigationTitle("ThisIsBad")
            }
            .tabItem {
                Image(systemName: "house")
            }
            .accessibilityLabel("Home")
            .tag(Tab.home)

            // MARK: Search Tab
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }
                .accessibilityLabel("Search")
                .tag(Tab.search)

            // MARK: Add Item Tab
            AddItemView(
                defaultLocation: selectedLocation,
                onSaveComplete: { selectedTab = .home },
                onCancel: { selectedTab = .home }
            )
            .tabItem {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add Item")
            .tag(Tab.addItem)

            // MARK: Grocery List Tab
            GroceryListView()
                .tabItem {
                    Image(systemName: "cart")
                }
                .accessibilityLabel("Grocery List")
                .tag(Tab.groceryList)

            // MARK: Settings Tab
            SettingsView(showDismissButton: false)
            .tabItem {
                Image(systemName: "gear")
            }
            .accessibilityLabel("Settings")
            .tag(Tab.settings)
        }
    }
}

// MARK: - Preview
// This allows you to see the view in Xcode's preview canvas
#Preview {
    ContentView()
        .modelContainer(for: [FoodItem.self, GroceryItem.self], inMemory: true)
        .environmentObject(NotificationService())
}
