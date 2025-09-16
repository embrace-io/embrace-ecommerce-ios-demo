import SwiftUI

struct MainTabView: View {
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @StateObject private var cartManager = CartManager()
    
    var body: some View {
        TabView(selection: $navigationCoordinator.selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                        .accessibilityIdentifier("homeTabIcon")
                    Text("Home")
                        .accessibilityIdentifier("homeTabLabel")
                }
                .accessibilityIdentifier("homeTab")
                .tag(Tab.home)

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                        .accessibilityIdentifier("searchTabIcon")
                    Text("Search")
                        .accessibilityIdentifier("searchTabLabel")
                }
                .accessibilityIdentifier("searchTab")
                .tag(Tab.search)

            CartView()
                .tabItem {
                    Image(systemName: "cart.fill")
                        .accessibilityIdentifier("cartTabIcon")
                    Text("Cart")
                        .accessibilityIdentifier("cartTabLabel")
                }
                .badge(cartManager.totalItems > 0 ? cartManager.totalItems : 0)
                .accessibilityIdentifier("cartTab")
                .tag(Tab.cart)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                        .accessibilityIdentifier("profileTabIcon")
                    Text("Profile")
                        .accessibilityIdentifier("profileTabLabel")
                }
                .accessibilityIdentifier("profileTab")
                .tag(Tab.profile)
        }
        .accessibilityIdentifier("mainTabView")
        .environmentObject(navigationCoordinator)
        .environmentObject(cartManager)
    }
}

enum Tab: String, CaseIterable {
    case home = "home"
    case search = "search"
    case cart = "cart"
    case profile = "profile"
    
    var displayName: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .cart: return "Cart"
        case .profile: return "Profile"
        }
    }
}

#Preview {
    MainTabView()
}
