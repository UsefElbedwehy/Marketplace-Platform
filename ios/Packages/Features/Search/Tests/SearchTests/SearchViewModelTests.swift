import Testing
import DomainKit
import DynamicForms
@testable import Search

@Suite @MainActor struct SearchViewModelTests {
    @Test func loadCategoriesFlattensNestedLeavesOnly() async {
        let leaf1 = CategoryTreeNode.fixture(id: "sedans", isLeaf: true)
        let leaf2 = CategoryTreeNode.fixture(id: "suvs", isLeaf: true)
        let parent = CategoryTreeNode(id: "vehicles", slug: "vehicles", name: "Vehicles", icon: nil, sortOrder: 0, isLeaf: false, children: [leaf1, leaf2])
        let viewModel = SearchViewModel(catalogUseCase: StubCatalogUseCase(tree: [parent]), listingUseCase: StubListingUseCase())

        await viewModel.loadCategories()

        #expect(viewModel.leafCategories.map(\.id).sorted() == ["sedans", "suvs"])
    }

    @Test func selectingACategoryBuildsAnEqualityFormStateFromFilterableNonNumberFields() async {
        let viewModel = SearchViewModel(catalogUseCase: StubCatalogUseCase(schema: .fixture()), listingUseCase: StubListingUseCase())

        await viewModel.selectCategory(.fixture())

        // brand (option, filterable) is included; mileage (number) and vin
        // (not filterable) are excluded from the equality form.
        let keys = viewModel.equalityFormState?.schema.allFields.map(\.key) ?? []
        #expect(keys == ["brand"])
    }

    @Test func numberFilterFieldsAreTheFilterableNumberFieldsOnly() async {
        let viewModel = SearchViewModel(catalogUseCase: StubCatalogUseCase(schema: .fixture()), listingUseCase: StubListingUseCase())

        await viewModel.selectCategory(.fixture())

        #expect(viewModel.numberFilterFields.map(\.key) == ["mileage"])
    }

    @Test func selectingACategoryImmediatelyRunsAnUnfilteredSearch() async {
        let listingUseCase = StubListingUseCase(page: Page(items: [.fixture()], nextCursor: nil, hasMore: false))
        let viewModel = SearchViewModel(catalogUseCase: StubCatalogUseCase(schema: .fixture()), listingUseCase: listingUseCase)

        await viewModel.selectCategory(.fixture())

        #expect(viewModel.results.count == 1)
    }

    @Test func currentFiltersCombinesEqualityAndRangeValues() async {
        let viewModel = SearchViewModel(catalogUseCase: StubCatalogUseCase(schema: .fixture()), listingUseCase: StubListingUseCase())
        await viewModel.selectCategory(.fixture())

        viewModel.equalityFormState?.setValue(.string("bmw"), for: viewModel.equalityFormState!.schema.allFields[0])
        viewModel.rangeValues["mileage"] = AttributeRangeFilter(lt: 100_000)

        let filters = viewModel.currentFilters(categoryId: "cat-cars")

        #expect(filters.attributes["brand"] == .equals(.string("bmw")))
        #expect(filters.attributes["mileage"] == .range(AttributeRangeFilter(lt: 100_000)))
    }

    @Test func runSearchPassesTheCurrentFiltersToTheUseCase() async {
        let listingUseCase = StubListingUseCase()
        let viewModel = SearchViewModel(catalogUseCase: StubCatalogUseCase(schema: .fixture()), listingUseCase: listingUseCase)
        await viewModel.selectCategory(.fixture())
        viewModel.equalityFormState?.setValue(.string("bmw"), for: viewModel.equalityFormState!.schema.allFields[0])

        await viewModel.runSearch()

        let captured = await listingUseCase.capturedFilters
        #expect(captured.last?.attributes["brand"] == .equals(.string("bmw")))
        #expect(captured.last?.categoryId == "cat-cars")
    }

    @Test func loadMoreResultsAppendsToExistingResults() async {
        let firstPage = Page<Listing>(items: [.fixture(id: "l1")], nextCursor: "cursor-1", hasMore: true)
        let listingUseCase = StubListingUseCase(page: firstPage)
        let viewModel = SearchViewModel(catalogUseCase: StubCatalogUseCase(schema: .fixture()), listingUseCase: listingUseCase)
        await viewModel.selectCategory(.fixture())
        #expect(viewModel.results.count == 1)

        await listingUseCase.setPage(Page(items: [.fixture(id: "l2")], nextCursor: nil, hasMore: false))
        await viewModel.loadMoreResults()

        #expect(viewModel.results.map(\.id) == ["l1", "l2"])
        #expect(viewModel.hasMoreResults == false)
    }

    @Test func clearSelectionResetsAllSearchState() async {
        let viewModel = SearchViewModel(catalogUseCase: StubCatalogUseCase(schema: .fixture()), listingUseCase: StubListingUseCase())
        await viewModel.selectCategory(.fixture())
        #expect(viewModel.selectedCategory != nil)

        viewModel.clearSelection()

        #expect(viewModel.selectedCategory == nil)
        #expect(viewModel.schema == nil)
        #expect(viewModel.equalityFormState == nil)
        #expect(viewModel.results.isEmpty)
    }
}

extension StubListingUseCase {
    func setPage(_ newPage: Page<Listing>) {
        page = newPage
    }
}
