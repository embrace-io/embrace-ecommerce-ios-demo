import SwiftUI

struct MainTabView: View {
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @StateObject private var cartManager = CartManager()
    
    var body: some View {
        TabView(selection: $navigationCoordinator.selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(Tab.home)
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(Tab.search)
            
            CartView()
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("Cart")
                }
                .badge(cartManager.totalItems > 0 ? cartManager.totalItems : 0)
                .tag(Tab.cart)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(Tab.profile)
        }
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
