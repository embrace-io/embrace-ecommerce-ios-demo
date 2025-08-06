import SwiftUI
import Combine

@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var navigationPath: [NavigationDestination] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupDeepLinkHandling()
    }
    
    func navigate(to destination: NavigationDestination) {
        navigationPath.append(destination)
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func navigateToRoot() {
        navigationPath.removeAll()
    }
    
    func switchTab(to tab: Tab) {
        selectedTab = tab
        navigationPath.removeAll()
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
            if let query = components.queryItems?.first(where: { $0.name == "q" })?.value {
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
}

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
}