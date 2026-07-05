import DesignSystem
import DomainKit
import DynamicForms
import SwiftUI

/// The dynamic filter sheet ⭐ — the same field-type registry that drives
/// `CreateListingView` also drives this, per docs/planning/05-dynamic-schema-
/// engine.md §6 ("the exact same renderer + registry powers the filter
/// sheet"). Only equality fields (option/bool) go through `DynamicFormView`;
/// number fields get a min/max range row instead (outside that renderer's
/// single-value model).
struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.semanticColors) private var colors
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let equalityFormState = viewModel.equalityFormState {
                        DynamicFormView(state: equalityFormState)
                    }
                    ForEach(viewModel.numberFilterFields) { field in
                        RangeFilterRow(field: field, range: Binding(
                            get: { viewModel.rangeValues[field.key] ?? AttributeRangeFilter() },
                            set: { viewModel.rangeValues[field.key] = $0 }
                        ))
                    }
                }
                .padding(20)
            }
            .background(colors.background)
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        Task { await viewModel.runSearch() }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
