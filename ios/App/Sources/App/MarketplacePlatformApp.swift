import SwiftUI

@main
struct MarketplacePlatformApp: App {
    init() {
        registerDependencies()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
