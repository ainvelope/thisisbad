import SwiftUI
import UIKit

// MARK: - Reorderable List View
// A UIKit-based table view that supports drag-and-drop reordering with haptic feedback.
// This provides a more reliable drag-and-drop experience than SwiftUI's native implementation.
struct ReorderableListView: UIViewControllerRepresentable {
    // MARK: - Properties

    // The food items to display
    let items: [FoodItem]

    // Callback when items are reordered
    let onReorder: (Int, Int) -> Void

    // Callback when an item is deleted
    let onDelete: (Int) -> Void

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UITableViewController {
        let tableViewController = UITableViewController(style: .plain)
        tableViewController.tableView.dataSource = context.coordinator
        tableViewController.tableView.delegate = context.coordinator
        tableViewController.tableView.dragDelegate = context.coordinator
        tableViewController.tableView.dropDelegate = context.coordinator
        tableViewController.tableView.dragInteractionEnabled = true
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FoodItemCell")

        // Enable editing mode for drag handles
        tableViewController.setEditing(true, animated: false)

        // Configure appearance
        tableViewController.tableView.separatorStyle = .singleLine
        tableViewController.tableView.rowHeight = UITableView.automaticDimension
        tableViewController.tableView.estimatedRowHeight = 70

        return tableViewController
    }

    func updateUIViewController(_ uiViewController: UITableViewController, context: Context) {
        context.coordinator.items = items
        context.coordinator.onReorder = onReorder
        context.coordinator.onDelete = onDelete
        uiViewController.tableView.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(items: items, onReorder: onReorder, onDelete: onDelete)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate, UITableViewDragDelegate, UITableViewDropDelegate {
        var items: [FoodItem]
        var onReorder: (Int, Int) -> Void
        var onDelete: (Int) -> Void
        private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

        init(items: [FoodItem], onReorder: @escaping (Int, Int) -> Void, onDelete: @escaping (Int) -> Void) {
            self.items = items
            self.onReorder = onReorder
            self.onDelete = onDelete
            super.init()
            feedbackGenerator.prepare()
        }

        // MARK: - UITableViewDataSource

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return items.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FoodItemCell", for: indexPath)
            let item = items[indexPath.row]

            var content = cell.defaultContentConfiguration()
            content.text = item.name
            content.secondaryText = item.expirationText
            content.secondaryTextProperties.color = colorForStatus(item.expirationStatus)

            // Add expiration date as tertiary info
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            content.prefersSideBySideTextAndSecondaryText = false

            cell.contentConfiguration = content
            cell.showsReorderControl = true

            return cell
        }

        // MARK: - UITableViewDelegate

        func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            return true
        }

        func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            feedbackGenerator.impactOccurred()
            onReorder(sourceIndexPath.row, destinationIndexPath.row)
        }

        func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
            return .delete
        }

        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                onDelete(indexPath.row)
            }
        }

        // MARK: - UITableViewDragDelegate

        func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
            feedbackGenerator.impactOccurred()
            let item = items[indexPath.row]
            let itemProvider = NSItemProvider(object: item.name as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            return [dragItem]
        }

        // MARK: - UITableViewDropDelegate

        func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
            if session.localDragSession != nil {
                return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
            return UITableViewDropProposal(operation: .cancel)
        }

        func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
            // Reordering is handled by moveRowAt
        }

        // MARK: - Helper Methods

        private func colorForStatus(_ status: ExpirationStatus) -> UIColor {
            switch status {
            case .safe:
                return .systemGreen
            case .warning:
                return .systemOrange
            case .expired:
                return .systemRed
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ReorderableListView(
        items: [
            FoodItem(
                name: "Milk",
                location: .fridge,
                expirationDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!
            ),
            FoodItem(
                name: "Yogurt",
                location: .fridge,
                expirationDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!
            )
        ],
        onReorder: { _, _ in },
        onDelete: { _ in }
    )
}
