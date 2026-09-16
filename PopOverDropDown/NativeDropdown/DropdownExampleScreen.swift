import SwiftUI
import NativeDropdown

struct DropdownExampleScreen: View {
    private static let cities = ["Bengaluru", "Chennai", "Delhi", "Hyderabad", "Jaipur", "Kolkata", "Mumbai", "Pune"]
        .map { DropdownItem(id: $0.lowercased(), name: $0) }

    private static let largeItems = (1...3000).map { DropdownItem(id: "\($0)", name: "Item \($0)") }

    @State private var basic: DropdownItem?
    @State private var city: DropdownItem?
    @State private var multiple: Set<DropdownItem> = []
    @State private var immediate: Set<DropdownItem> = []
    @State private var restricted: DropdownItem?
    @State private var domain: DropdownItem?
    @State private var toolbarSelection: DropdownItem?
    @State private var dynamic: DropdownItem?
    @State private var items = cities
    @State private var basicIsValid = false
    @State private var submitted = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Native dropdowns")
                        .font(.title2.bold())
                    Text("Reusable selections anchored to your own SwiftUI views.")
                        .foregroundStyle(.secondary)
                }
                Section("1 · Basic single selection · Required") {
                    NativeDropdown(items: Self.cities, selection: $basic,
                                   configuration: .init(isSelectionRequired: true),
                                   onValidationChange: { basicIsValid = $0 }) {
                        Label(basic?.name ?? "Select an item", systemImage: "chevron.up.chevron.down")
                    }
                    .accessibilityIdentifier("example.basic")
                    Button("Validate selection") { submitted = true }
                    if submitted {
                        Text(basicIsValid ? "Selection is valid." : "Choose an item before continuing.")
                            .foregroundStyle(basicIsValid ? .secondary : .primary)
                    }
                }
                Section("2 · Searchable field") {
                    NativeDropdown(items: Self.cities, selection: $city,
                                   configuration: .init(isSearchEnabled: true,
                                                        isSelectionRequired: true)) {
                        HStack {
                            Text(city?.name ?? "Select city")
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                        .padding(12)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("example.search")
                }
                Section("3 · Multiple selection · Apply / Cancel") {
                    NativeDropdown(items: Self.cities, selections: $multiple,
                                   configuration: .init(isSearchEnabled: true,
                                                        isSelectionRequired: true)) {
                        Label("\(multiple.count) selected", systemImage: "checklist")
                    }
                    .accessibilityIdentifier("example.multiple")
                    selectionSummary(multiple)
                }
                Section("4 · Disabled rows") {
                    NativeDropdown(items: Self.cities, selection: $restricted,
                                   configuration: .init(isSearchEnabled: true, isSelectionRequired: true),
                                   isItemSelectable: { $0.id != "delhi" }) {
                        Text(restricted?.name ?? "Select an available city")
                    }
                    .accessibilityIdentifier("example.disabled")
                    Text("Delhi is unavailable.").font(.footnote).foregroundStyle(.secondary)
                }
                Section("5 · List row anchor") {
                    NativeDropdown(items: [DropdownItem(id: "design", name: "Design"),
                                           DropdownItem(id: "engineering", name: "Engineering")],
                                   selection: $domain) {
                        HStack {
                            Text("Domain")
                            Spacer()
                            Text(domain?.name ?? "Select").foregroundStyle(.secondary)
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Section("6 · Immediate, optional multiple selection") {
                    NativeDropdown(items: Self.cities, selections: $immediate,
                                   configuration: .init(showsApplyButton: false)) {
                        Text("\(immediate.count) selected")
                    }
                    selectionSummary(immediate)
                }
                Section("7 · Dynamic data / Empty state") {
                    NativeDropdown(items: items, selection: $dynamic,
                                   configuration: .init(isSearchEnabled: true)) {
                        Text(dynamic?.name ?? "Select from current items")
                    }
                    Button(items.isEmpty ? "Restore items" : "Remove all items") {
                        items = items.isEmpty ? Self.cities : []
                    }
                    Text("Default policy keeps your selection when items disappear.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("8 · Long list") {
                    NativeDropdown(items: Self.largeItems,
                                   selection: $toolbarSelection,
                                   configuration: .init(isSearchEnabled: true),
                                   trigger: { open in
                        Button(action: open) {
                            Label(toolbarSelection?.name ?? "Browse 3,000 items", systemImage: "list.bullet")
                        }
                        .buttonStyle(.bordered)
                    })
                }
            }
            .navigationTitle("Dropdown examples")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NativeDropdown(items: Self.cities, selection: $city) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .accessibilityLabel("Choose city")
                    }
                }
            }
        }
    }

    private func selectionSummary(_ items: Set<DropdownItem>) -> some View {
        Text(items.isEmpty ? "Nothing selected" : items.map(\.name).sorted().joined(separator: ", "))
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

#Preview { DropdownExampleScreen() }
#Preview("Dark") { DropdownExampleScreen().preferredColorScheme(.dark) }
#Preview("Large text") { DropdownExampleScreen().environment(\.dynamicTypeSize, .accessibility3) }
