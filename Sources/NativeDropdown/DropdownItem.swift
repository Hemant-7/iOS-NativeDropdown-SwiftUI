import SwiftUI

/// Supply stable, unique IDs when mapping your API models.
public struct DropdownItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

enum DropdownSelectionMode {
    case single
    case multiple
}

public enum DropdownMissingItemPolicy: Sendable {
    /// Preserve the parent's values, including their names, until the parent changes them.
    case keep
    /// Remove values whose IDs are absent. Never chooses a replacement.
    case remove
}

public struct DropdownConfiguration: Sendable {
    public var isSearchEnabled = false
    public var isSelectionRequired = false
    public var dismissOnSingleSelection = true
    public var showsApplyButton = true
    /// Opt in to Clear selection / Done for single-selection popovers.
    public var showsSingleSelectionActions = false
    public var searchPlaceholder = "Search"
    public var emptyMessage = "No items available"
    public var noResultsMessage = "No results found"
    public var doneButtonTitle = "Done"
    public var applyButtonTitle = "Apply"
    public var cancelButtonTitle = "Cancel"
    public var clearButtonTitle = "Clear selection"
    public var missingItemPolicy: DropdownMissingItemPolicy = .keep

    public init(
        isSearchEnabled: Bool = false,
        isSelectionRequired: Bool = false,
        dismissOnSingleSelection: Bool = true,
        showsApplyButton: Bool = true,
        showsSingleSelectionActions: Bool = false,
        searchPlaceholder: String = "Search",
        emptyMessage: String = "No items available",
        noResultsMessage: String = "No results found",
        doneButtonTitle: String = "Done",
        applyButtonTitle: String = "Apply",
        cancelButtonTitle: String = "Cancel",
        clearButtonTitle: String = "Clear selection",
        missingItemPolicy: DropdownMissingItemPolicy = .keep
    ) {
        self.isSearchEnabled = isSearchEnabled
        self.isSelectionRequired = isSelectionRequired
        self.dismissOnSingleSelection = dismissOnSingleSelection
        self.showsApplyButton = showsApplyButton
        self.showsSingleSelectionActions = showsSingleSelectionActions
        self.searchPlaceholder = searchPlaceholder
        self.emptyMessage = emptyMessage
        self.noResultsMessage = noResultsMessage
        self.doneButtonTitle = doneButtonTitle
        self.applyButtonTitle = applyButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
        self.clearButtonTitle = clearButtonTitle
        self.missingItemPolicy = missingItemPolicy
    }
}

/// Shared selection rules use IDs, so a renamed item remains selected.
enum DropdownRules {
    static func uniqueItems(_ items: [DropdownItem]) -> [DropdownItem] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }
    }

    static func filtered(_ items: [DropdownItem], query: String) -> [DropdownItem] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let items = uniqueItems(items)
        return query.isEmpty ? items : items.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    static func reconciled(_ selection: Set<DropdownItem>, items: [DropdownItem],
                           policy: DropdownMissingItemPolicy) -> Set<DropdownItem> {
        guard policy == .remove else { return selection }
        let ids = Set(items.map(\.id))
        return selection.filter { ids.contains($0.id) }
    }

    static func toggled(_ item: DropdownItem, in selection: Set<DropdownItem>,
                        mode: DropdownSelectionMode, required: Bool,
                        selectable: Bool) -> Set<DropdownItem> {
        guard selectable else { return selection }
        if mode == .single { return [item] }
        let remaining = selection.filter { $0.id != item.id }
        if remaining.count != selection.count {
            return required && remaining.isEmpty ? selection : remaining
        }
        return selection.union([item])
    }
}
