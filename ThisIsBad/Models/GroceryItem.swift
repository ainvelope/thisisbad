import SwiftData
import Foundation

// MARK: - Grocery Item Model
// A shopping list item - something the user needs to buy.
@Model
class GroceryItem {
    var id: UUID
    var name: String
    var isCompleted: Bool
    var dateAdded: Date

    init(name: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.name = name
        self.isCompleted = isCompleted
        self.dateAdded = Date()
    }
}
