import Core
import DomainKit
import DynamicForms
import Observation

@Observable
@MainActor
final class CreateListingViewModel {
    private(set) var selectedCategory: CategoryTreeNode?
    private(set) var formState: DynamicFormState?
    private(set) var isLoadingSchema = false
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?
    private(set) var titleError: String?
    private(set) var createdListing: Listing?

    var title = ""
    var description = ""
    var priceText = ""
    var currency = "SAR"

    private let catalogUseCase: CatalogUseCase
    private let listingUseCase: ListingUseCase

    init(catalogUseCase: CatalogUseCase = Container.shared.catalogUseCase(), listingUseCase: ListingUseCase = Container.shared.listingUseCase()) {
        self.catalogUseCase = catalogUseCase
        self.listingUseCase = listingUseCase
    }

    func selectCategory(_ node: CategoryTreeNode, locale: String = "en") async {
        selectedCategory = node
        formState = nil
        errorMessage = nil
        isLoadingSchema = true
        defer { isLoadingSchema = false }
        do {
            let schema = try await catalogUseCase.fetchSchema(categoryId: node.id, locale: locale)
            formState = DynamicFormState(schema: schema)
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }

    /// Re-fetches the current category's schema — proves "edit a schema
    /// server-side → app reflects it after refresh, no rebuild" (roadmap
    /// Phase 4 exit criterion) since this is a plain network refetch, no
    /// client-side caching of the schema shape to invalidate.
    func refreshSchema(locale: String = "en") async {
        guard let category = selectedCategory else { return }
        await selectCategory(category, locale: locale)
    }

    func submit(defaultCurrency: String) async -> Bool {
        guard let category = selectedCategory, let formState else { return false }

        titleError = nil
        errorMessage = nil

        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            titleError = "Title is required."
            return false
        }
        guard formState.validate() else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        let draft = CreateListingDraft(
            categoryId: category.id,
            title: title,
            description: description.isEmpty ? nil : description,
            price: Double(priceText),
            currency: currency.isEmpty ? defaultCurrency : currency,
            attributes: formState.submittableAttributes
        )

        do {
            createdListing = try await listingUseCase.createListing(draft)
            return true
        } catch let DomainError.validation(fields) {
            formState.applyServerErrors(fields.filter { $0.field != "title" })
            titleError = fields.first(where: { $0.field == "title" })?.message
            return false
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
            return false
        }
    }

    func reset() {
        selectedCategory = nil
        formState = nil
        title = ""
        description = ""
        priceText = ""
        createdListing = nil
        errorMessage = nil
        titleError = nil
    }
}
