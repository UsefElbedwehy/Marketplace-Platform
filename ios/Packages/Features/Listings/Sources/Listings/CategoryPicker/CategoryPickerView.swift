import DesignSystem
import DomainKit
import SwiftUI

/// A sheet-presented two-level drill-down (own local `NavigationStack`,
/// rather than pushing onto the host tab's stack — a self-contained "pick a
/// leaf category" flow, the same UX shape as a Contacts/Photos picker).
public struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.semanticColors) private var colors
    @State private var viewModel = CategoryPickerViewModel()
    @State private var path: [CategoryTreeNode] = []
    let onSelect: (CategoryTreeNode) -> Void

    public init(onSelect: @escaping (CategoryTreeNode) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        NavigationStack(path: $path) {
            content(for: viewModel.tree)
                .navigationTitle("Choose a category")
                .navigationDestination(for: CategoryTreeNode.self) { node in
                    content(for: node.children).navigationTitle(node.name)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
        .task { await viewModel.load() }
        .background(colors.background)
    }

    @ViewBuilder
    private func content(for nodes: [CategoryTreeNode]) -> some View {
        if viewModel.isLoading && nodes.isEmpty {
            LoadingIndicator()
        } else if let error = viewModel.errorMessage {
            ErrorStateView(message: error) { Task { await viewModel.load() } }
        } else {
            List(nodes.sorted(by: { $0.sortOrder < $1.sortOrder })) { node in
                if node.isLeaf {
                    Button {
                        onSelect(node)
                        dismiss()
                    } label: {
                        HStack {
                            Text(node.name).foregroundStyle(colors.textPrimary)
                            Spacer()
                        }
                    }
                    .accessibilityIdentifier("category.\(node.slug)")
                } else {
                    NavigationLink(value: node) {
                        Text(node.name).foregroundStyle(colors.textPrimary)
                    }
                    .accessibilityIdentifier("category.\(node.slug)")
                }
            }
            .listStyle(.plain)
        }
    }
}
