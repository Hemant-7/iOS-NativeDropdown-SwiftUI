import SwiftUI

@MainActor
struct DropdownPopoverContent: View {
    let items: [DropdownItem]
    let selected: Set<DropdownItem>
    let mode: DropdownSelectionMode
    let configuration: DropdownConfiguration
    let isItemSelectable: (DropdownItem) -> Bool
    let onSelect: (DropdownItem) -> Void
    let onClear: () -> Void
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var searchText = ""
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var rowsHeight: CGFloat?
    private let horizontalInset: CGFloat = 16

    private var results: [DropdownItem] {
        DropdownRules.filtered(items, query: configuration.isSearchEnabled ? searchText : "")
    }
    private var invalid: Bool { configuration.isSelectionRequired && selected.isEmpty }
    private var usesDraft: Bool { mode == .multiple && configuration.showsApplyButton }
    private var showsActions: Bool {
        mode == .multiple || configuration.showsSingleSelectionActions
            || !configuration.dismissOnSingleSelection || verticalSizeClass == .compact
    }

    var body: some View {
        // Compute once per update, never once per row or divider.
        let results = results
        let selectedIDs = Set(selected.map(\.id))
        return VStack(spacing: 0) {
            if configuration.isSearchEnabled {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField(configuration.searchPlaceholder, text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("dropdown.search")
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(12)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, horizontalInset)
                .padding(.bottom, 8)
            }

            if results.isEmpty {
                ContentUnavailableView(
                    items.isEmpty ? configuration.emptyMessage : configuration.noResultsMessage,
                    systemImage: items.isEmpty ? "list.bullet" : "magnifyingglass"
                )
                .frame(maxHeight: 240)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        if results.count > 8 {
                            // A bounded viewport lets SwiftUI create only nearby rows.
                            LazyVStack(spacing: 0) {
                                rows(results, selectedIDs: selectedIDs)
                            }
                        } else {
                            // Only small lists need exact measurement to avoid bottom gaps.
                            VStack(spacing: 0) {
                                rows(results, selectedIDs: selectedIDs)
                            }
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                                rowsHeight = height
                            }
                        }
                    }
                    .frame(height: results.count > 8 ? 420 : rowsHeight.map { min($0, 420) })
                    .frame(maxHeight: 420)
                    .scrollBounceBehavior(.basedOnSize)
                    .onChange(of: searchText) { _, _ in
                        if let first = results.first { proxy.scrollTo(first.id, anchor: .top) }
                    }
                }
            }

            if showsActions {
                Divider()
                ViewThatFits(in: .horizontal) {
                    HStack { actions }
                    VStack { actions }
                }
                .padding()
            }
        }
        .padding(.top, 12)
        .padding(.bottom, showsActions ? 0 : 4)
        .frame(idealWidth: 340, maxWidth: 480)
        .background(.clear)
    }

    @ViewBuilder private var actions: some View {
        if usesDraft {
            Button(configuration.cancelButtonTitle, role: .cancel, action: onCancel)
                .accessibilityIdentifier("dropdown.cancel")
        } else if mode == .single && configuration.showsSingleSelectionActions
                    && !configuration.isSelectionRequired && !selected.isEmpty {
            Button(configuration.clearButtonTitle, action: onClear)
        }
        Spacer(minLength: 8)
        Button(usesDraft ? configuration.applyButtonTitle : configuration.doneButtonTitle, action: onComplete)
            .fontWeight(.semibold)
            .disabled(mode == .multiple && invalid)
            .accessibilityIdentifier("dropdown.complete")
    }

    private func rows(_ items: [DropdownItem], selectedIDs: Set<String>) -> some View {
        let lastID = items.last?.id
        return ForEach(items) { item in
            row(item, isSelected: selectedIDs.contains(item.id))
                .id(item.id)
                .overlay(alignment: .bottom) {
                    if item.id != lastID {
                        Divider().padding(.horizontal, horizontalInset)
                    }
                }
        }
    }

    private func row(_ item: DropdownItem, isSelected: Bool) -> some View {
        let canSelect = isItemSelectable(item)
        return Button { onSelect(item) } label: {
            HStack(spacing: 12) {
                Text(item.name)
                    .foregroundStyle(canSelect ? .primary : .secondary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 12)
                if mode == .multiple {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                } else if isSelected {
                    Image(systemName: "checkmark").foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canSelect)
        .opacity(canSelect ? 1 : 0.5)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("dropdown.item.\(item.id)")
    }
}
