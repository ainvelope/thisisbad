import SwiftUI

// MARK: - Food Item Row
// A single row displaying a food item in the list.
// Shows the item name, expiration countdown, and status indicator.
struct FoodItemRow: View {
    // MARK: - Properties

    // The food item to display
    let item: FoodItem

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // MARK: Status Indicator
            // Shows a colored icon based on expiration status.
            // We use both color AND icon for accessibility.
            Image(systemName: item.expirationStatus.iconName)
                .foregroundStyle(statusColor)
                .font(.title2)
                .accessibilityLabel(item.expirationStatus.accessibilityLabel)

            // MARK: Item Details
            VStack(alignment: .leading, spacing: 4) {
                // Item name
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)

                // Expiration countdown text
                Text(item.expirationText)
                    .font(.subheadline)
                    .foregroundStyle(statusColor)

                // Optional notes (if present)
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // MARK: Expiration Date
            // Show the actual expiration date on the right
            VStack(alignment: .trailing) {
                Text(item.expirationDate, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        // Accessibility: Read all the important info together
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.expirationText), \(item.expirationStatus.accessibilityLabel)")
    }

    // MARK: - Computed Properties

    // Convert the status color name to a SwiftUI Color
    private var statusColor: Color {
        switch item.expirationStatus {
        case .safe:
            return .green
        case .warning:
            return .orange
        case .expired:
            return .red
        }
    }
}

// MARK: - Preview
#Preview {
    // Create sample items for preview
    List {
        // Item expiring in 7 days (safe - green)
        FoodItemRow(item: FoodItem(
            name: "Milk",
            location: .fridge,
            expirationDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            notes: "2% organic"
        ))

        // Item expiring in 2 days (warning - orange)
        FoodItemRow(item: FoodItem(
            name: "Yogurt",
            location: .fridge,
            expirationDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        ))

        // Item already expired (expired - red)
        FoodItemRow(item: FoodItem(
            name: "Chicken",
            location: .fridge,
            expirationDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        ))
    }
}
