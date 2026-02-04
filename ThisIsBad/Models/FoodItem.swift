import SwiftData
import Foundation

// MARK: - Size Unit
// Units for food item size (e.g., 2 gal, 500 ml).
// CaseIterable for picker; none case for optional field.
enum SizeUnit: String, Codable, CaseIterable, Identifiable {
    case none = ""
    case oz = "oz"
    case quart = "quart"
    case gal = "gal"
    case lbs = "lbs"
    case ml = "ml"
    case liter = "L"
    case ltr = "ltr"
    case cup = "cup"
    case pint = "pint"
    case g = "g"
    case kg = "kg"

    var id: String { rawValue }

    var displayName: String {
        self == .none ? "—" : rawValue
    }

    /// Parse a size string (e.g. "2 gal") into quantity and unit.
    static func parse(_ sizeString: String?) -> (quantity: String, unit: SizeUnit) {
        let trimmed = sizeString?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return ("", .none) }

        let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        if parts.count == 2 {
            let q = String(parts[0])
            let u = String(parts[1])
            if let unit = SizeUnit(rawValue: u) {
                return (q, unit)
            }
            return (q, .none)
        }
        if parts.count == 1 {
            let single = String(parts[0])
            if Double(single) != nil {
                return (single, .none)
            }
            if let unit = SizeUnit(rawValue: single) {
                return ("", unit)
            }
        }
        return (trimmed, .none)
    }

    /// Build a size string from quantity and unit.
    static func format(quantity: String, unit: SizeUnit) -> String? {
        let q = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasQuantity = !q.isEmpty && Double(q) != nil
        let hasUnit = unit != .none

        if hasQuantity && hasUnit {
            return "\(q) \(unit.rawValue)"
        }
        if hasQuantity {
            return q
        }
        if hasUnit {
            return unit.rawValue
        }
        return nil
    }
}

// MARK: - Storage Location
// This enum defines where food can be stored in your home.
// CaseIterable lets us loop through all cases (useful for pickers).
// Codable allows the enum to be saved/loaded from storage.
enum StorageLocation: String, Codable, CaseIterable, Identifiable {
    case fridge = "Fridge"
    case freezer = "Freezer"
    case pantry = "Pantry"

    // Identifiable requires an 'id' property - we use the raw string value
    var id: String { rawValue }

    // SF Symbol icon name for each location (used in the UI)
    var iconName: String {
        switch self {
        case .fridge: return "refrigerator"
        case .freezer: return "snowflake"
        case .pantry: return "cabinet"
        }
    }
}

// MARK: - Item Status
// Tracks what happened to the food item
enum ItemStatus: String, Codable {
    case active = "Active"       // Still in storage
    case used = "Used"           // Consumed/cooked
    case discarded = "Discarded" // Thrown away (expired, spoiled, etc.)
}

// MARK: - Expiration Status
// Visual status based on how close to expiration the item is
enum ExpirationStatus {
    case safe       // More than 3 days until expiration (green)
    case warning    // 1-3 days until expiration (yellow/orange)
    case expired    // Expiration date has passed (red)

    // Color name for SwiftUI (these are built-in colors)
    var colorName: String {
        switch self {
        case .safe: return "green"
        case .warning: return "orange"
        case .expired: return "red"
        }
    }

    // SF Symbol icon for accessibility (not just color)
    var iconName: String {
        switch self {
        case .safe: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .expired: return "xmark.circle.fill"
        }
    }

    // Text description for VoiceOver accessibility
    var accessibilityLabel: String {
        switch self {
        case .safe: return "Safe to eat"
        case .warning: return "Expiring soon"
        case .expired: return "Expired"
        }
    }
}

// MARK: - Food Item Model
// @Model is a SwiftData macro that makes this class persistable.
// SwiftData automatically saves changes to this model to device storage.
@Model
class FoodItem {
    // Unique identifier for each item (used for notifications)
    var id: UUID

    // The name of the food (e.g., "Milk", "Chicken breast")
    var name: String

    // Where the item is stored
    // Note: We store the raw value because SwiftData works better with primitive types
    private var locationRaw: String

    // The date when the food expires
    var expirationDate: Date

    // Optional notes (e.g., "opened Jan 15", "homemade")
    var notes: String?

    // Current status of the item
    private var statusRaw: String

    // When the item was added to the app
    var dateAdded: Date

    // Amount remaining (0...1, where 1.0 = 100%). Default 1.0 for new and legacy items.
    var remainingAmount: Double = 1.0

    // Optional size/unit (e.g., gal, ltr, oz, quart)
    var size: String?

    // MARK: - Computed Properties

    // Convert the raw string back to the StorageLocation enum
    var location: StorageLocation {
        get { StorageLocation(rawValue: locationRaw) ?? .fridge }
        set { locationRaw = newValue.rawValue }
    }

    // Convert the raw string back to the ItemStatus enum
    var status: ItemStatus {
        get { ItemStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    // Calculate days until expiration (negative means expired)
    var daysUntilExpiration: Int {
        // Get the start of today (midnight) for accurate day calculation
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiry = calendar.startOfDay(for: expirationDate)

        // Calculate the number of days between today and expiration
        let components = calendar.dateComponents([.day], from: today, to: expiry)
        return components.day ?? 0
    }

    // Determine the visual status based on days remaining
    var expirationStatus: ExpirationStatus {
        let days = daysUntilExpiration
        if days < 0 {
            return .expired
        } else if days <= 3 {
            return .warning
        } else {
            return .safe
        }
    }

    // Human-readable text for the expiration countdown
    var expirationText: String {
        let days = daysUntilExpiration
        if days < 0 {
            let absDays = abs(days)
            return absDays == 1 ? "Expired 1 day ago" : "Expired \(absDays) days ago"
        } else if days == 0 {
            return "Expires today"
        } else if days == 1 {
            return "Expires tomorrow"
        } else {
            return "Expires in \(days) days"
        }
    }

    // MARK: - Initializer

    init(name: String, location: StorageLocation, expirationDate: Date, notes: String? = nil, remainingAmount: Double = 1.0, size: String? = nil) {
        self.id = UUID()
        self.name = name
        self.locationRaw = location.rawValue
        self.expirationDate = expirationDate
        self.notes = notes
        self.statusRaw = ItemStatus.active.rawValue
        self.dateAdded = Date()
        self.remainingAmount = min(max(remainingAmount, 0), 1)
        self.size = size?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : size?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
