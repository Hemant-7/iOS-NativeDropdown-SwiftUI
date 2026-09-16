import Testing
@testable import NativeDropdown

@MainActor
struct PopOverDropDownTests {
    let a = DropdownItem(id: "a", name: "Alpha")
    let b = DropdownItem(id: "b", name: "Beta")

    @Test func searchTrimsWhitespaceAndIgnoresCase() {
        #expect(DropdownRules.filtered([a, b], query: "  ALP\n") == [a])
        #expect(DropdownRules.filtered([a, b], query: "  ") == [a, b])
        #expect(DropdownRules.filtered([a, b], query: "absent").isEmpty)
    }

    @Test func singleReplacesAndDisabledItemDoesNothing() {
        #expect(DropdownRules.toggled(b, in: [a], mode: .single, required: true, selectable: true) == [b])
        #expect(DropdownRules.toggled(b, in: [a], mode: .single, required: false, selectable: false) == [a])
    }

    @Test func requiredMultipleProtectsFinalSelection() {
        #expect(DropdownRules.toggled(a, in: [a], mode: .multiple, required: true, selectable: true) == [a])
        #expect(DropdownRules.toggled(a, in: [a, b], mode: .multiple, required: true, selectable: true) == [b])
        #expect(DropdownRules.toggled(a, in: [a], mode: .multiple, required: false, selectable: true).isEmpty)
        #expect(DropdownRules.toggled(a, in: [], mode: .multiple, required: true, selectable: true) == [a])
    }

    @Test func identitySurvivesRenaming() {
        let renamed = DropdownItem(id: "a", name: "New name")
        #expect(DropdownRules.toggled(renamed, in: [a, b], mode: .multiple, required: false, selectable: true) == [b])
        #expect(DropdownRules.reconciled([a], items: [renamed], policy: .remove) == [a])
        #expect(DropdownRules.uniqueItems([a, renamed, b]) == [a, b])
    }

    @Test func missingItemPoliciesNeverInsertDefaults() {
        #expect(DropdownRules.reconciled([a, b], items: [b], policy: .keep) == [a, b])
        #expect(DropdownRules.reconciled([a, b], items: [b], policy: .remove) == [b])
        #expect(DropdownRules.reconciled([a], items: [], policy: .remove).isEmpty)
        #expect(DropdownRules.reconciled([], items: [b], policy: .keep).isEmpty)
    }
}
