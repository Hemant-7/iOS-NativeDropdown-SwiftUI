import SwiftUI
import Testing
import NativeDropdown

/// Uses only the exported API, as a consuming application would.
@MainActor
struct PublicAPITests {
    @Test func consumerCanConstructAllAnchorAndBindingVariants() {
        let item = DropdownItem(id: "1", name: "First")
        let configuration = DropdownConfiguration(isSearchEnabled: true, missingItemPolicy: .remove)
        let single = Binding<DropdownItem?>.constant(item)
        let multiple = Binding<Set<DropdownItem>>.constant([item])
        _ = NativeDropdown(items: [item], selection: single, configuration: configuration) { Text("Choose") }
        _ = NativeDropdown(items: [item], selections: multiple) { Text("Choose") }
        _ = NativeDropdown(items: [item], selection: single, trigger: { open in Button("Choose", action: open) })
        _ = NativeDropdown(items: [item], selections: multiple, trigger: { open in Button("Choose", action: open) })
        #expect(configuration.isSearchEnabled)
        #expect(item.id == "1")
    }
}
