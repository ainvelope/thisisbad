import SwiftUI
import SwiftData

// MARK: - Content View
// This is the main view of the app, containing the location tabs and navigation.
struct ContentView: View {
    // MARK: - Properties

    // @State creates a mutable property that SwiftUI watches for changes.
    // When this changes, the view automatically updates.
    @State private var selectedLocation: StorageLocation = .fridge

    // Controls whether the "Add Item" sheet is showing
    @State private var showingAddItem = false

    // Controls whether the Settings sheet is showing
    @State private var showingSettings = false

    // MARK: - Body

    var body: some View {
        // NavigationStack provides navigation bar and navigation capabilities
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Location Picker
                // A segmented control to switch between Fridge/Freezer/Pantry
                Picker("Storage Location", selection: $selectedLocation) {
                    // Loop through all storage locations
                    ForEach(StorageLocation.allCases) { location in
                        // Show icon and text for each location
                        Label(location.rawValue, systemImage: location.iconName)
                            .tag(location)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // MARK: Food List
                // Display the list of items for the selected location
                FoodListView(location: selectedLocation)
            }
            .navigationTitle("ThisIsBad")
            .toolbar {
                // MARK: Toolbar Items

                // Settings button (top left)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityLabel("Settings")
                }

                // Add item button (top right)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add food item")
                }
            }
            // Present the Add Item view as a sheet (slides up from bottom)
            .sheet(isPresented: $showingAddItem) {
                AddItemView(defaultLocation: selectedLocation)
            }
            // Present the Settings view as a sheet
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - Preview
// This allows you to see the view in Xcode's preview canvas
#Preview {
    ContentView()
        .modelContainer(for: FoodItem.self, inMemory: true)
        .environmentObject(NotificationService())
}
