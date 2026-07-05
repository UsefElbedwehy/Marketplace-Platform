import DesignSystem
import DomainKit
import SwiftUI

public struct SearchView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    @State private var viewModel = SearchViewModel()
    @State private var isFiltering = false
    let onSelect: (Listing) -> Void

    public init(onSelect: @escaping (Listing) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        Group {
            if viewModel.selectedCategory == nil {
                categoryList
            } else {
                results
            }
        }
        .navigationTitle(viewModel.selectedCategory?.name ?? "Search")
        .toolbar {
            if viewModel.selectedCategory != nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Categories") { viewModel.clearSelection() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Filters") { isFiltering = true }
                        .accessibilityIdentifier("search.filters-button")
                }
            }
        }
        .sheet(isPresented: $isFiltering) {
            FilterSheetView(viewModel: viewModel)
        }
        .background(colors.background)
        .task { await viewModel.loadCategories() }
    }

    private var categoryList: some View {
        List(viewModel.leafCategories) { node in
            Button(node.name) {
                Task { await viewModel.selectCategory(node) }
            }
            .foregroundStyle(colors.textPrimary)
            .accessibilityIdentifier("search.category.\(node.slug)")
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.isLoadingCategories { LoadingIndicator() }
        }
    }

    private var results: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) { Task { await viewModel.runSearch() } }
                } else if viewModel.isLoadingSchema {
                    LoadingIndicator()
                } else if viewModel.results.isEmpty && !viewModel.isLoadingResults {
                    EmptyStateView(title: "No matches", message: "Try adjusting your filters.")
                }

                ForEach(viewModel.results) { listing in
                    Button { onSelect(listing) } label: {
                        SearchResultRowView(listing: listing)
                    }
                    .accessibilityIdentifier("search-result.\(listing.id)")
                }

                if viewModel.hasMoreResults {
                    ProgressView().onAppear { Task { await viewModel.loadMoreResults() } }
                } else if viewModel.isLoadingResults {
                    LoadingIndicator()
                }
            }
            .padding(16)
        }
    }
}
