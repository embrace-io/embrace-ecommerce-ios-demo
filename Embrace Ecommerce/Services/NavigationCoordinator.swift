import SwiftUI
import Combine

@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var homeNavigationPath: [NavigationDestination] = []
    @Published var searchNavigationPath: [NavigationDestination] = []
    @Published var cartNavigationPath: [NavigationDestination] = []
    @Published var profileNavigationPath: [NavigationDestination] = []

    var navigationPath: [NavigationDestination] {
        get {
            switch selectedTab {
            case .home: return homeNavigationPath
            case .search: return searchNavigationPath
            case .cart: return cartNavigationPath
            case .profile: return profileNavigationPath
            }
        }
        set {
            switch selectedTab {
            case .home: homeNavigationPath = newValue
            case .search: searchNavigationPath = newValue
            case .cart: cartNavigationPath = newValue
            case .profile: profileNavigationPath = newValue
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupDeepLinkHandling()
    }
    
    func navigate(to destination: NavigationDestination) {
        switch selectedTab {
        case .home: homeNavigationPath.append(destination)
        case .search: searchNavigationPath.append(destination)
        case .cart: cartNavigationPath.append(destination)
        case .profile: profileNavigationPath.append(destination)
        }
    }

    func navigateBack() {
        switch selectedTab {
        case .home:
            if !homeNavigationPath.isEmpty { homeNavigationPath.removeLast() }
        case .search:
            if !searchNavigationPath.isEmpty { searchNavigationPath.removeLast() }
        case .cart:
            if !cartNavigationPath.isEmpty { cartNavigationPath.removeLast() }
        case .profile:
            if !profileNavigationPath.isEmpty { profileNavigationPath.removeLast() }
        }
    }

    func navigateToRoot() {
        switch selectedTab {
        case .home: homeNavigationPath.removeAll()
        case .search: searchNavigationPath.removeAll()
        case .cart: cartNavigationPath.removeAll()
        case .profile: profileNavigationPath.removeAll()
        }
    }

    func switchTab(to tab: Tab) {
        selectedTab = tab
    }
    
    func handleDeepLink(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else {
            return
        }
        
        switch host {
        case "product":
            if let productId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                switchTab(to: .home)
                navigate(to: .productDetail(productId: productId))
            }
        case "cart":
            switchTab(to: .cart)
        case "profile":
            switchTab(to: .profile)
        case "search":
            switchTab(to: .search)
            if let _ = components.queryItems?.first(where: { $0.name == "q" })?.value {
                // Will implement search functionality later
            }
        default:
            break
        }
    }
    
    private func setupDeepLinkHandling() {
        NotificationCenter.default.publisher(for: .deepLinkReceived)
            .compactMap { $0.object as? URL }
            .sink { [weak self] url in
                self?.handleDeepLink(url: url)
            }
            .store(in: &cancellables)
    }
}

enum NavigationDestination: Hashable {
    case productDetail(productId: String)
    case productList(category: String?)
    case checkout
    case orderConfirmation(orderId: String)
    case profile
    case editProfile
    case addressBook
    case paymentMethods
    case orderHistory
    case networkSettings
    case networkDebug
}

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
}