import SwiftUI

/// The label initializer supplies a native Button. For an existing Button or other
/// interactive anchor, use the `trigger:` initializer and invoke its supplied action.
@MainActor
public struct NativeDropdown<Anchor: View>: View {
    private let items: [DropdownItem]
    private let selection: Binding<Set<DropdownItem>>
    private let mode: DropdownSelectionMode
    private let configuration: DropdownConfiguration
    private let isItemSelectable: (DropdownItem) -> Bool
    private let onSelectionChange: (Set<DropdownItem>) -> Void
    private let onPresent: () -> Void
    private let onDismiss: () -> Void
    private let onValidationChange: (Bool) -> Void
    private let anchor: (@escaping () -> Void) -> Anchor

    @State private var isPresented = false
    @State private var draft: Set<DropdownItem> = []

    public init(
        items: [DropdownItem], selection: Binding<DropdownItem?>,
        configuration: DropdownConfiguration = .init(),
        isItemSelectable: @escaping (DropdownItem) -> Bool = { _ in true },
        onSelectionChange: @escaping (DropdownItem?) -> Void = { _ in },
        onPresent: @escaping () -> Void = {}, onDismiss: @escaping () -> Void = {},
        onValidationChange: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder trigger: @escaping (@escaping () -> Void) -> Anchor
    ) {
        self.items = items
        self.selection = Binding(
            get: { selection.wrappedValue.map { Set([$0]) } ?? [] },
            set: { selection.wrappedValue = $0.first }
        )
        self.mode = .single
        self.configuration = configuration
        self.isItemSelectable = isItemSelectable
        self.onSelectionChange = { onSelectionChange($0.first) }
        self.onPresent = onPresent
        self.onDismiss = onDismiss
        self.onValidationChange = onValidationChange
        self.anchor = trigger
    }

    public init(
        items: [DropdownItem], selections: Binding<Set<DropdownItem>>,
        configuration: DropdownConfiguration = .init(),
        isItemSelectable: @escaping (DropdownItem) -> Bool = { _ in true },
        onSelectionChange: @escaping (Set<DropdownItem>) -> Void = { _ in },
        onPresent: @escaping () -> Void = {}, onDismiss: @escaping () -> Void = {},
        onValidationChange: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder trigger: @escaping (@escaping () -> Void) -> Anchor
    ) {
        self.items = items
        self.selection = selections
        self.mode = .multiple
        self.configuration = configuration
        self.isItemSelectable = isItemSelectable
        self.onSelectionChange = onSelectionChange
        self.onPresent = onPresent
        self.onDismiss = onDismiss
        self.onValidationChange = onValidationChange
        self.anchor = trigger
    }

    private var usesDraft: Bool { mode == .multiple && configuration.showsApplyButton }
    private var current: Set<DropdownItem> { usesDraft ? draft : selection.wrappedValue }
    private var isValid: Bool { !configuration.isSelectionRequired || !selection.wrappedValue.isEmpty }
    private var isCurrentValid: Bool { !configuration.isSelectionRequired || !current.isEmpty }

    public var body: some View {
        anchor(present)
            .popover(isPresented: $isPresented, attachmentAnchor: .rect(.bounds)) {
                DropdownPopoverContent(
                    items: items, selected: current, mode: mode,
                    configuration: configuration, isItemSelectable: isItemSelectable,
                    onSelect: select, onClear: { commit([]) },
                    onComplete: complete,
                    onCancel: { isPresented = false }
                )
                // Native anchored popover in portrait; allow the system's full-screen
                // adaptation in compact-height environments (e.g. landscape phones).
                .presentationCompactAdaptation(horizontal: .popover, vertical: .fullScreenCover)
                .interactiveDismissDisabled(mode == .multiple && !isCurrentValid)
            }
            .onChange(of: isPresented) { _, presented in
                if presented { onPresent() } else { onDismiss() }
            }
            .onChange(of: selection.wrappedValue) { _, _ in
                // Parent changes win over in-progress edits. Cancel never writes back.
                reconcile()
                if usesDraft { draft = selection.wrappedValue }
            }
            .onChange(of: items) { _, _ in reconcile() }
            .onChange(of: usesDraft) { _, _ in draft = selection.wrappedValue }
            .onChange(of: configuration.missingItemPolicy) { _, _ in reconcile() }
            .onChange(of: isValid, initial: true) { _, valid in onValidationChange(valid) }
            .onAppear { reconcile() }
    }

    private func present() {
        reconcile()
        draft = selection.wrappedValue
        isPresented = true
    }

    private func select(_ item: DropdownItem) {
        guard items.contains(where: { $0.id == item.id }), isItemSelectable(item) else { return }
        let next = DropdownRules.toggled(item, in: current, mode: mode,
                                         required: configuration.isSelectionRequired, selectable: true)
        if usesDraft { draft = next } else { commit(next) }
        if mode == .single && configuration.dismissOnSingleSelection { isPresented = false }
    }

    private func complete() {
        guard isCurrentValid || mode == .single else { return }
        if usesDraft { commit(draft) }
        isPresented = false
    }

    private func commit(_ values: Set<DropdownItem>) {
        guard selection.wrappedValue != values else { return }
        selection.wrappedValue = values
        onSelectionChange(values)
    }

    private func reconcile() {
        commit(DropdownRules.reconciled(selection.wrappedValue, items: items,
                                       policy: configuration.missingItemPolicy))
        draft = DropdownRules.reconciled(draft, items: items, policy: configuration.missingItemPolicy)
    }
}

extension NativeDropdown {
    public init<Label: View>(
        items: [DropdownItem], selection: Binding<DropdownItem?>,
        configuration: DropdownConfiguration = .init(),
        isItemSelectable: @escaping (DropdownItem) -> Bool = { _ in true },
        onSelectionChange: @escaping (DropdownItem?) -> Void = { _ in },
        onPresent: @escaping () -> Void = {}, onDismiss: @escaping () -> Void = {},
        onValidationChange: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder anchor: @escaping () -> Label
    ) where Anchor == Button<Label> {
        self.init(items: items, selection: selection, configuration: configuration,
                  isItemSelectable: isItemSelectable, onSelectionChange: onSelectionChange,
                  onPresent: onPresent, onDismiss: onDismiss, onValidationChange: onValidationChange,
                  trigger: { open in Button(action: open, label: anchor) })
    }

    public init<Label: View>(
        items: [DropdownItem], selections: Binding<Set<DropdownItem>>,
        configuration: DropdownConfiguration = .init(),
        isItemSelectable: @escaping (DropdownItem) -> Bool = { _ in true },
        onSelectionChange: @escaping (Set<DropdownItem>) -> Void = { _ in },
        onPresent: @escaping () -> Void = {}, onDismiss: @escaping () -> Void = {},
        onValidationChange: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder anchor: @escaping () -> Label
    ) where Anchor == Button<Label> {
        self.init(items: items, selections: selections, configuration: configuration,
                  isItemSelectable: isItemSelectable, onSelectionChange: onSelectionChange,
                  onPresent: onPresent, onDismiss: onDismiss, onValidationChange: onValidationChange,
                  trigger: { open in Button(action: open, label: anchor) })
    }
}
