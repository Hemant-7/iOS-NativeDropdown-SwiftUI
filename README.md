# NativeDropdown

A reusable, 100% SwiftUI dropdown for iPhone and iPad. Anchor a native popover to a button, field-like view, list row, card, or toolbar item.

- Single or multiple selection with typed bindings
- Optional search, required selection, and disabled items
- Draft Apply/Cancel or immediate multiple-selection updates
- Lazy row rendering for large lists, with a 3,000-item example
- Configurable text, callbacks, and missing-item policy
- No UIKit wrappers or third-party dependencies

## Requirements

**Package:** iOS 17+, Xcode 16+, Swift 6 tools. iOS/iPadOS only.

**Included demo:** Xcode 27 and iOS 27 (its original deployment target).

## Install with Xcode

1. Choose **File → Add Package Dependencies…**.
2. Enter `https://github.com/Hemant-7/iOS-NativeDropdown-SwiftUI.git`.
3. Select **Up to Next Major Version**, starting at **1.0.1**.
4. Add the **NativeDropdown** product to your app target.
5. Add `import NativeDropdown` where you use the dropdown.

## Install with Package.swift

```swift
.package(
    url: "https://github.com/Hemant-7/iOS-NativeDropdown-SwiftUI.git",
    from: "1.0.1"
)
```

Add this product to your target's `dependencies`:

```swift
.product(name: "NativeDropdown", package: "ios-nativedropdown-swiftui")
```

## Single selection

```swift
import SwiftUI
import NativeDropdown

struct CityPicker: View {
    @State private var city: DropdownItem?

    private let cities = [
        DropdownItem(id: "blr", name: "Bengaluru"),
        DropdownItem(id: "del", name: "Delhi"),
        DropdownItem(id: "mum", name: "Mumbai")
    ]

    var body: some View {
        NativeDropdown(
            items: cities,
            selection: $city,
            configuration: .init(isSearchEnabled: true)
        ) {
            HStack {
                Text(city?.name ?? "Choose a city")
                Image(systemName: "chevron.down")
            }
        }
    }
}
```

The trailing closure supplies the label of a native button. Choosing an item dismisses the popover by default. There is no title, selection hint, or default single-selection footer.

## Multiple selection

```swift
struct CityFilters: View {
    @State private var cities: Set<DropdownItem> = []
    let options: [DropdownItem]

    var body: some View {
        NativeDropdown(
            items: options,
            selections: $cities,
            configuration: .init(
                isSearchEnabled: true,
                isSelectionRequired: true,
                showsApplyButton: true
            ),
            isItemSelectable: { $0.id != "restricted" },
            onSelectionChange: { committedValues in
                print(committedValues)
            }
        ) {
            Text("\(cities.count) selected")
        }
    }
}
```

Apply commits the draft. Cancel discards it. Set `showsApplyButton: false` for immediate updates. The binding type determines the selection mode.

## Existing buttons and custom anchors

Avoid nesting a Button inside the label initializer. Use `trigger:` for an interactive anchor:

```swift
NativeDropdown(items: options, selection: $city, trigger: { open in
    Button("Choose city", action: open)
        .buttonStyle(.borderedProminent)
})
```

The same component can be placed inside `List` or `ToolbarItem`.

## Behavior to know

- Use stable, unique item IDs when mapping API models. Selection indicators match by ID.
- `.keep` preserves selections when items disappear. Set `missingItemPolicy: .remove` to prune missing IDs; neither policy chooses a default.
- Required multiple selection disables empty Apply/Done, prevents deselecting the final item, and blocks interactive dismissal while empty. **Cancel abandons the draft**, even if the original parent value is empty. Validate required fields before submitting the parent screen.
- `onValidationChange` reports committed nonempty-selection validity. Business rules remain in the parent.
- External parent selection changes replace pending draft edits.
- Single-selection footer actions are opt-in through `showsSingleSelectionActions`; Done is retained when needed to exit a non-auto-dismissing presentation.
- Large arrays use lazy row rendering, not network pagination. Supply your fetched items to `items` and update them as data arrives.

See the [full API and behavior guide](Documentation/Usage.md) for configuration defaults, callbacks, and more examples.

## Run the example

Clone this repository and open `PopOverDropDown.xcodeproj`. Select the **PopOverDropDown** scheme and an iOS 27 simulator. The app uses the package through a local Swift package reference; there is one copy of the component source.

## Tests

The demo test target runs the shared package unit tests and public API checks:

```sh
xcodebuild -project PopOverDropDown.xcodeproj -scheme PopOverDropDown \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:PopOverDropDownTests test
```

Choose an installed iOS 27 simulator name. Omit `-only-testing` to include UI tests. To test the package independently, open `Package.swift` in Xcode and test the NativeDropdown scheme on an iOS simulator. `swift test` on the macOS host is not supported because the library targets iOS.

## License

MIT. See [LICENSE](LICENSE).
