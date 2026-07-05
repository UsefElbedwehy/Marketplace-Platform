import DesignSystem
import SwiftUI

struct MainTabView: View {
    @Bindable var coordinator: TabCoordinator
    let appCoordinator: AppCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            NavigationStack(path: $coordinator.homePath) {
                HomeTabView(path: $coordinator.homePath)
            }
            .tabItem { Label(TabCoordinator.Tab.home.title, systemImage: TabCoordinator.Tab.home.systemImage) }
            .tag(TabCoordinator.Tab.home)

            NavigationStack(path: $coordinator.searchPath) {
                SearchTabView(path: $coordinator.searchPath)
            }
            .tabItem { Label(TabCoordinator.Tab.search.title, systemImage: TabCoordinator.Tab.search.systemImage) }
            .tag(TabCoordinator.Tab.search)

            NavigationStack(path: $coordinator.sellPath) {
                SellTabView(path: $coordinator.sellPath)
            }
            .tabItem { Label(TabCoordinator.Tab.sell.title, systemImage: TabCoordinator.Tab.sell.systemImage) }
            .tag(TabCoordinator.Tab.sell)

            NavigationStack(path: $coordinator.chatPath) {
                ChatTabView(path: $coordinator.chatPath)
            }
            .tabItem { Label(TabCoordinator.Tab.chat.title, systemImage: TabCoordinator.Tab.chat.systemImage) }
            .tag(TabCoordinator.Tab.chat)

            NavigationStack(path: $coordinator.profilePath) {
                ProfileView(coordinator: appCoordinator, path: $coordinator.profilePath)
            }
            .tabItem { Label(TabCoordinator.Tab.profile.title, systemImage: TabCoordinator.Tab.profile.systemImage) }
            .tag(TabCoordinator.Tab.profile)
        }
    }
}
