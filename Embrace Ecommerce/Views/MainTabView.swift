import SwiftUI

struct MainTabView: View {
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @StateObject private var cartManager = CartManager()
    
    var body: some View {
        TabView(selection: $navigationCoordinator.selectedTab) {
            NavigationStack(path: $navigationCoordinator.homeNavigationPath) {
                HomeView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Image(systemName: "house.fill")
                    .accessibilityIdentifier("homeTabIcon")
                Text("Home")
                    .accessibilityIdentifier("homeTabLabel")
            }
            .accessibilityIdentifier("homeTab")
            .tag(Tab.home)

            NavigationStack(path: $navigationCoordinator.searchNavigationPath) {
                SearchView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                    .accessibilityIdentifier("searchTabIcon")
                Text("Search")
                    .accessibilityIdentifier("searchTabLabel")
            }
            .accessibilityIdentifier("searchTab")
            .tag(Tab.search)

            NavigationStack(path: $navigationCoordinator.cartNavigationPath) {
                CartView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Image(systemName: "cart.fill")
                    .accessibilityIdentifier("cartTabIcon")
                Text("Cart")
                    .accessibilityIdentifier("cartTabLabel")
            }
            .badge(cartManager.totalItems > 0 ? cartManager.totalItems : 0)
            .accessibilityIdentifier("cartTab")
            .tag(Tab.cart)

            NavigationStack(path: $navigationCoordinator.profileNavigationPath) {
                ProfileView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
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

    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .checkout:
            CheckoutView()
        case .productDetail(let productId):
            ProductDetailView(productId: productId)
        case .productList(let category):
            ProductListView(category: category)
        case .profile:
            ProfileView()
        case .editProfile:
            EditProfileView()
        case .addressBook:
            AddressBookView()
        case .paymentMethods:
            PaymentMethodsView()
        case .orderHistory:
            OrderHistoryView()
        case .networkSettings:
            NetworkSettingsView()
        case .networkDebug:
            NetworkDebugView()
        case .orderConfirmation(let orderId):
            Text("Order Confirmation: \(orderId)")
                .navigationTitle("Order Confirmed")
        }
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
