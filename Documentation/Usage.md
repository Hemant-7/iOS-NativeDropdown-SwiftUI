# NativeDropdown

Reusable code lives in `Sources/NativeDropdown`. The existing Xcode demo consumes the local package.

## Files

- **Sources/NativeDropdown/DropdownItem.swift**: public item/configuration types and internal selection rules.
- **Sources/NativeDropdown/NativeDropdown.swift**: public SwiftUI component and typed binding initializers.
- **Sources/NativeDropdown/DropdownPopoverContent.swift**: internal search, lazy rows, sizing, and actions.
- **PopOverDropDown/NativeDropdown/DropdownExampleScreen.swift**: all example scenarios, including 3,000 items.
- **PopOverDropDownTests**: package unit tests, shared with the example's test target.
- **PopOverDropDownUITests**: simulator interaction tests for the example app.

## Basic API

```swift
@State private var selectedItem: DropdownItem?
@State private var selectedItems: Set<DropdownItem> = []

// Map any API model into DropdownItem with a stable, unique ID.
let items = [DropdownItem(id: "design", name: "Design")]

NativeDropdown(
    items: items,
    selection: $selectedItem,
    configuration: .init(isSelectionRequired: true)
) {
    Text(selectedItem?.name ?? "Select item")
}

NativeDropdown(
    items: items,
    selections: $selectedItems,
    configuration: .init(isSearchEnabled: true, isSelectionRequired: true),
    isItemSelectable: { $0.id != "restricted" },
    onSelectionChange: { values in print(values) }
) {
    Text("\(selectedItems.count) selected")
}
```

The binding type selects `.single` or `.multiple` automatically; callers cannot accidentally mismatch a selection mode and binding. Anchor content in these initializers is the **label of a native Button**. Supply Text, Label, a field-like view, row, or card. Apply normal SwiftUI button styles to the dropdown.

For an existing interactive view, use `trigger:` to avoid nested buttons:

```swift
NativeDropdown(items: items, selection: $selectedItem, trigger: { open in
    Button("Choose", action: open)
        .buttonStyle(.borderedProminent)
})
```

Place either form inside `List` or `ToolbarItem`. The native popover attaches to the supplied view's bounds; the system chooses its arrow placement.

## Configuration

| Property | Default | Effect |
| --- | --- | --- |
| isSearchEnabled | false | Adds a search field without reserving space when disabled |
| isSelectionRequired | false | Validates nonempty selection; never inserts a default |
| dismissOnSingleSelection | true | Dismisses after a single choice |
| showsApplyButton | true | Multiple selection uses a temporary draft; false writes immediately |
| missingItemPolicy | .keep | `.remove` removes selections with absent IDs |
| showsSingleSelectionActions | false | Opt in to Clear selection / Done for single selection |
| searchPlaceholder | Search | Search field prompt |
| emptyMessage | No items available | Empty source state |
| noResultsMessage | No results found | Empty search state |
| doneButtonTitle / applyButtonTitle | Done / Apply | Completion actions |
| cancelButtonTitle / clearButtonTitle | Cancel / Clear selection | Other actions |

`isItemSelectable` defaults to `{ _ in true }`. Disabled items remain visible and accessible as disabled buttons; they never update or dismiss the selection. Existing disabled selections are preserved.

## Selection and validation contract

- Single selection replaces the previous value. Optional single selection provides Clear selection when `showsSingleSelectionActions` is true. Single-selection footers are hidden by default. Done remains available when automatic dismissal is off, so the user can always exit. Required single selection can be dismissed without choosing; the parent validates before submitting.
- Required multiple selection prevents deselecting the final value. An initially empty selection remains empty until the user chooses an item. Apply/Done is disabled and native interactive dismissal is blocked while empty.
- **Cancel explicitly abandons a draft transaction**, even when the parent started empty. It does not complete or commit an invalid selection. This also provides an escape when the source is empty or all items are disabled. The parent must still validate required fields before screen submission.
- Apply commits once. Outside dismissal of a valid draft discards uncommitted edits, like Cancel. Immediate mode updates the binding on every change and has no rollback.
- Parent binding changes during a draft replace pending edits. Cancel never writes an old snapshot back to the parent. Reopening always starts from the current binding, with empty search.
- `onSelectionChange` is strongly typed (`DropdownItem?` or `Set<DropdownItem>`). It fires for component writes, including missing-item removal, but not draft taps or external parent writes. `onPresent` / `onDismiss` track presentation state transitions, not animation completion.
- `onValidationChange(Bool)` reports initial and subsequent **committed** required-selection validity. This checks nonemptiness only. Validate membership, selectable status, and business rules separately in the parent as needed.
- Matching uses IDs, so names can change without losing the checkmark. `.keep` leaves parent objects unchanged, including old names. `.remove` prunes absent IDs without choosing replacements. Supply unique IDs; duplicate source IDs are defensively displayed only once (first occurrence wins). Set bindings should likewise contain one item per ID.
- Search trims outer whitespace, matches names case-insensitively, and never changes source items or selection.

## Native presentation and compatibility

The package supports **iOS 17+** and requires **Xcode 16+ / Swift 6 tools**. The demo app retains its existing iOS 27 target and needs Xcode 27. Both portrait and landscape request a native anchored popover. The scrolling viewport can shrink to the available height, including when the keyboard is shown. iPad uses an anchored popover. Native system colors, multiline text, and scalable controls support Dark Mode and Dynamic Type.

The single-value `onGeometryChange` API used for short-list sizing is back-deployed; the build requires a recent SDK. Package source has no UIKit imports, third-party dependencies, force unwraps, manual screen-coordinate positioning, or global mutable state.

## Verification

Selection/search rules are tested in the existing unit-test target. Native selection, searching, required Apply state, draft cancellation, and disabled accessibility controls are exercised in the existing UI-test target. Tests stay in their normal Xcode test groups so they are not shipped in the app.

Verified with Xcode 27.0: build succeeded; all 5 unit tests and 2 UI tests passed on both iPhone 18 Pro and iPad Pro 11-inch (M5), running iOS 27. Dark Mode and large-text previews are included; a full manual VoiceOver and accessibility-size audit was not performed.

### Optional single-selection footer

```swift
// Default: no title and no single-selection footer.
let minimal = DropdownConfiguration()

// Opt in only on screens that need these controls.
let withActions = DropdownConfiguration(
    showsSingleSelectionActions: true
)
```

Popovers never display a title or selection-validation hints. Multiple-selection Apply/Cancel or Done actions remain available. Required-selection rules and parent validation callbacks still apply. Row content determines the scrolling area height, capped at 420 points; separators appear only between items.

## Large datasets

Lists with more than eight results use a `LazyVStack` inside a bounded 420-point scroll viewport. SwiftUI creates rows as they approach the visible area. Eight or fewer results use exact content measurement to preserve compact sizing without bottom gaps. Search filters the source once per view update, rather than repeating the full search for every separator. Selected IDs are indexed once per update for constant-time row checks. Search changes return to the first result.

The example stores its 3,000-item dataset once, rather than rebuilding it during selection updates. This is lazy **row rendering**, not network pagination: callers still supply the loaded item array.
