import DesignSystem
import DomainKit
import DynamicForms
import SwiftUI

/// The golden-path proof ⭐ (docs/planning/11-roadmap.md Phase 4): the exact
/// same view renders a listing form for Cars, Apartments, Phones, or any
/// other category — zero vertical-specific code, driven entirely by the
/// category's `ComposedSchema` via `DynamicFormView`.
public struct CreateListingView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    @State private var viewModel = CreateListingViewModel()
    @State private var isPickingCategory = false
    let defaultCurrency: String
    let onCreated: (Listing) -> Void

    public init(defaultCurrency: String = "SAR", onCreated: @escaping (Listing) -> Void) {
        self.defaultCurrency = defaultCurrency
        self.onCreated = onCreated
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                categorySection

                if let error = viewModel.errorMessage {
                    Text(error).font(theme.typography.footnote.font).foregroundStyle(colors.danger)
                }

                if viewModel.isLoadingSchema {
                    LoadingIndicator()
                } else if let formState = viewModel.formState {
                    coreFields
                    DynamicFormView(state: formState)
                    submitButton
                }
            }
            .padding(20)
        }
        .background(colors.background)
        .navigationTitle("New listing")
        .sheet(isPresented: $isPickingCategory) {
            CategoryPickerView { node in
                Task { await viewModel.selectCategory(node) }
            }
        }
        .onChange(of: viewModel.createdListing) { _, listing in
            if let listing { onCreated(listing) }
        }
    }

    private var categorySection: some View {
        Button {
            isPickingCategory = true
        } label: {
            Card {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Category").font(theme.typography.caption.font).foregroundStyle(colors.textSecondary)
                        Text(viewModel.selectedCategory?.name ?? "Choose a category…")
                            .font(theme.typography.headline.font)
                            .foregroundStyle(viewModel.selectedCategory == nil ? colors.placeholder : colors.textPrimary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(colors.textSecondary)
                }
            }
        }
        .accessibilityIdentifier("create-listing.category-picker")
    }

    private var coreFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppTextField("Title", text: $viewModel.title, errorMessage: viewModel.titleError)
                .accessibilityIdentifier("create-listing.title")
            AppTextField("Description", text: $viewModel.description)
            HStack {
                AppTextField("Price", text: $viewModel.priceText)
                    .accessibilityIdentifier("create-listing.price")
                AppTextField("Currency", text: $viewModel.currency)
            }
        }
    }

    private var submitButton: some View {
        PrimaryButton(viewModel.isSubmitting ? "Publishing…" : "Create listing", isLoading: viewModel.isSubmitting) {
            Task { _ = await viewModel.submit(defaultCurrency: defaultCurrency) }
        }
        .disabled(viewModel.isSubmitting)
        .accessibilityIdentifier("create-listing.submit")
    }
}
