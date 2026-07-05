import Testing
import DomainKit
@testable import Listings

@Suite @MainActor struct CategoryPickerViewModelTests {
    @Test func loadPopulatesTheTree() async {
        let node = CategoryTreeNode.fixture(id: "c1")
        let viewModel = CategoryPickerViewModel(catalogUseCase: StubCatalogUseCase(tree: [node]))

        await viewModel.load()

        #expect(viewModel.tree == [node])
        #expect(viewModel.isLoading == false)
    }

    @Test func loadSurfacesAnErrorMessage() async {
        struct Boom: Error {}
        let viewModel = CategoryPickerViewModel(catalogUseCase: StubCatalogUseCase(error: Boom()))

        await viewModel.load()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.tree.isEmpty)
    }
}
