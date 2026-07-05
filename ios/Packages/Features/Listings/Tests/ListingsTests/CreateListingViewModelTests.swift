import Testing
import Core
import DomainKit
import DynamicForms
@testable import Listings

@Suite @MainActor struct CreateListingViewModelTests {
    @Test func selectingACategoryFetchesItsSchemaAndBuildsFormState() async {
        let viewModel = CreateListingViewModel(catalogUseCase: StubCatalogUseCase(schema: .fixture(schemaVersion: 7)), listingUseCase: StubListingUseCase())

        await viewModel.selectCategory(.fixture())

        #expect(viewModel.formState?.schema.schemaVersion == 7)
        #expect(viewModel.selectedCategory?.id == "c1")
    }

    @Test func submitWithoutATitleFailsWithoutCallingTheUseCase() async {
        let listingUseCase = StubListingUseCase()
        let viewModel = CreateListingViewModel(catalogUseCase: StubCatalogUseCase(), listingUseCase: listingUseCase)
        await viewModel.selectCategory(.fixture())

        let succeeded = await viewModel.submit(defaultCurrency: "SAR")

        #expect(succeeded == false)
        #expect(viewModel.titleError != nil)
        let created = await listingUseCase.createdDraft
        #expect(created == nil)
    }

    @Test func submitWithAMissingRequiredAttributeFailsClientSideValidation() async {
        let viewModel = CreateListingViewModel(catalogUseCase: StubCatalogUseCase(), listingUseCase: StubListingUseCase())
        await viewModel.selectCategory(.fixture())
        viewModel.title = "2019 BMW"
        // brand is required by the fixture schema and never set.

        let succeeded = await viewModel.submit(defaultCurrency: "SAR")

        #expect(succeeded == false)
        #expect(viewModel.formState?.fieldErrors["brand"] != nil)
    }

    @Test func submitSucceedsAndCapturesTheCreatedListing() async {
        let listingUseCase = StubListingUseCase(listing: .fixture(id: "new-1"))
        let viewModel = CreateListingViewModel(catalogUseCase: StubCatalogUseCase(), listingUseCase: listingUseCase)
        await viewModel.selectCategory(.fixture())
        viewModel.title = "2019 BMW"
        viewModel.formState?.setValue(.string("bmw"), for: viewModel.formState!.schema.allFields[0])

        let succeeded = await viewModel.submit(defaultCurrency: "SAR")

        #expect(succeeded == true)
        #expect(viewModel.createdListing?.id == "new-1")
        let draft = await listingUseCase.createdDraft
        #expect(draft?.categoryId == "c1")
        #expect(draft?.title == "2019 BMW")
        #expect(draft?.attributes["brand"] == .string("bmw"))
    }

    @Test func submitMapsA422IntoFieldErrorsOnTheFormState() async {
        struct ValidationBoom: Error {}
        let listingUseCase = StubListingUseCase(createResult: .failure(DomainError.validation([
            FieldError(field: "brand", code: "invalid_option", message: "not a real brand"),
        ])))
        let viewModel = CreateListingViewModel(catalogUseCase: StubCatalogUseCase(), listingUseCase: listingUseCase)
        await viewModel.selectCategory(.fixture())
        viewModel.title = "2019 BMW"
        viewModel.formState?.setValue(.string("not-a-brand"), for: viewModel.formState!.schema.allFields[0])

        let succeeded = await viewModel.submit(defaultCurrency: "SAR")

        #expect(succeeded == false)
        #expect(viewModel.formState?.fieldErrors["brand"] == "not a real brand")
        #expect(viewModel.createdListing == nil)
    }

    @Test func refreshSchemaRefetchesForTheCurrentlySelectedCategory() async {
        // Proves the "edit a schema server-side -> app reflects it after
        // refresh" exit criterion is just a plain refetch, no client cache
        // to invalidate.
        var callCount = 0
        final class CountingCatalogUseCase: CatalogUseCase, @unchecked Sendable {
            var schema: ComposedSchema = .fixture(schemaVersion: 1)
            var onFetch: () -> Void = {}
            func fetchTree(locale: String) async throws -> [CategoryTreeNode] { [] }
            func fetchSchema(categoryId: String, locale: String) async throws -> ComposedSchema { onFetch(); return schema }
            func fetchOptions(attributeId: String, parentOptionId: String?, locale: String) async throws -> [AttributeOption] { [] }
        }
        let catalogUseCase = CountingCatalogUseCase()
        catalogUseCase.onFetch = { callCount += 1 }
        let viewModel = CreateListingViewModel(catalogUseCase: catalogUseCase, listingUseCase: StubListingUseCase())

        await viewModel.selectCategory(.fixture())
        #expect(viewModel.formState?.schema.schemaVersion == 1)

        catalogUseCase.schema = .fixture(schemaVersion: 2)
        await viewModel.refreshSchema()

        #expect(callCount == 2)
        #expect(viewModel.formState?.schema.schemaVersion == 2)
    }
}
