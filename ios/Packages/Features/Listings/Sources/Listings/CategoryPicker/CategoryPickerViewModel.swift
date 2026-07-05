import Core
import DomainKit
import Observation

@Observable
@MainActor
final class CategoryPickerViewModel {
    private(set) var tree: [CategoryTreeNode] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // Constructor-injected (defaulting to the Factory-resolved production
    // instance) rather than a bare `@Injected` property — tests pass a fake
    // directly with zero shared-container mutation, so concurrent tests
    // never race on a global registration.
    private let catalogUseCase: CatalogUseCase

    init(catalogUseCase: CatalogUseCase = Container.shared.catalogUseCase()) {
        self.catalogUseCase = catalogUseCase
    }

    func load(locale: String = "en") async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            tree = try await catalogUseCase.fetchTree(locale: locale)
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }
}
