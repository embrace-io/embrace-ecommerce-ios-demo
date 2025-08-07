import Foundation

struct Category: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let imageUrl: String?
    let subcategories: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, subcategories
        case imageUrl = "image_url"
    }
}

enum AuthState {
    case guest
    case loggedIn(User)
    case anonymous
}

@MainActor
class MockDataService: ObservableObject {
    static let shared = MockDataService()
    
    @Published var authState: AuthState = .anonymous
    @Published var isLoading = false
    
    private var cachedProducts: [Product] = []
    private var cachedCategories: [Category] = []
    
    private init() {
        loadLocalData()
    }
    
    private func loadLocalData() {
        loadProductsFromJSON()
        loadCategoriesFromJSON()
    }
    
    private func loadProductsFromJSON() {
        guard let url = Bundle.main.url(forResource: "products", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            loadFallbackProducts()
            return
        }
        
        do {
            cachedProducts = try JSONDecoder().decode([Product].self, from: data)
        } catch {
            print("Failed to decode products.json: \(error)")
            loadFallbackProducts()
        }
    }
    
    private func loadCategoriesFromJSON() {
        guard let url = Bundle.main.url(forResource: "categories", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            loadFallbackCategories()
            return
        }
        
        do {
            cachedCategories = try JSONDecoder().decode([Category].self, from: data)
        } catch {
            print("Failed to decode categories.json: \(error)")
            loadFallbackCategories()
        }
    }
    
    private func loadFallbackProducts() {
        cachedProducts = [
            Product(
                id: "fallback_1",
                name: "Sample Product",
                description: "This is a fallback product when JSON loading fails",
                price: 99.99,
                currency: "USD",
                imageUrls: [],
                category: "Electronics",
                brand: "Sample Brand",
                variants: [],
                inStock: true,
                stockCount: 10,
                weight: 2.5,
                dimensions: ProductDimensions(width: 12, height: 8, depth: 4)
            )
        ]
    }
    
    private func loadFallbackCategories() {
        cachedCategories = [
            Category(
                id: "fallback_1",
                name: "Electronics",
                description: "Electronic devices",
                imageUrl: nil,
                subcategories: ["Smartphones", "Laptops"]
            )
        ]
    }
    
    func getFeaturedProducts() -> [Product] {
        Array(cachedProducts.shuffled().prefix(6))
    }
    
    func getProducts(for category: String?) -> [Product] {
        if let category = category {
            return cachedProducts.filter { 
                $0.category.lowercased() == category.lowercased() 
            }
        }
        return cachedProducts
    }
    
    func getProduct(by id: String) -> Product? {
        cachedProducts.first { $0.id == id }
    }
    
    func searchProducts(query: String) -> [Product] {
        let lowercasedQuery = query.lowercased()
        return cachedProducts.filter { product in
            product.name.lowercased().contains(lowercasedQuery) ||
            product.description.lowercased().contains(lowercasedQuery) ||
            product.category.lowercased().contains(lowercasedQuery) ||
            (product.brand?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
    
    func getCategories() -> [Category] {
        cachedCategories
    }
    
    func getCategoryNames() -> [String] {
        cachedCategories.map { $0.name }
    }
    
    func mockLogin(email: String = "user@example.com", password: String = "password") -> User {
        let user = User(
            id: UUID().uuidString,
            email: email,
            firstName: "John",
            lastName: "Doe",
            phoneNumber: "+1 555-0123",
            dateJoined: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(),
            isGuest: false,
            preferences: UserPreferences(
                newsletter: true,
                pushNotifications: true,
                biometricAuth: true,
                preferredCurrency: "USD"
            )
        )
        
        authState = .loggedIn(user)
        saveCurrentUser(user)
        return user
    }
    
    func mockGuestLogin() -> User {
        let guestUser = User(
            id: "guest_\(UUID().uuidString)",
            email: "guest@example.com",
            firstName: "Guest",
            lastName: "User",
            phoneNumber: nil,
            dateJoined: Date(),
            isGuest: true,
            preferences: nil
        )
        
        authState = .guest
        saveCurrentUser(guestUser)
        return guestUser
    }
    
    func getCurrentUser() -> User? {
        switch authState {
        case .loggedIn(let user):
            return user
        case .guest:
            return loadCurrentUser()
        case .anonymous:
            return nil
        }
    }
    
    func logout() {
        authState = .anonymous
        UserDefaults.standard.removeObject(forKey: "current_user")
    }
    
    private func saveCurrentUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "current_user")
        }
    }
    
    private func loadCurrentUser() -> User? {
        guard let userData = UserDefaults.standard.data(forKey: "current_user"),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return nil
        }
        return user
    }
    
    func simulateNetworkError() -> MockNetworkError {
        let errors: [MockNetworkError] = [
            .noConnection,
            .timeout,
            .serverError(code: 500),
            .serverError(code: 503),
            .invalidData,
            .notFound
        ]
        return errors.randomElement() ?? .timeout
    }
    
    func getRandomDelay(fast: Bool = false) -> TimeInterval {
        if fast {
            return Double.random(in: 0.1...0.5)
        } else {
            return Double.random(in: 0.5...2.0)
        }
    }
}