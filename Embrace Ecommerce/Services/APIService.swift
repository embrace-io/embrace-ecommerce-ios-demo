import Foundation
import Combine

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
    @Published var isLoading = false
    @Published var useRealAPI = false
    
    private let networkService = NetworkService.shared
    private let mockNetworkService = MockNetworkService.shared
    private let mockDataService = MockDataService.shared
    
    private init() {}
    
    func fetchProducts(category: String? = nil, limit: Int? = nil, offset: Int? = nil) async throws -> [Product] {
        if useRealAPI {
            let request = ProductsRequest(category: category, limit: limit, offset: offset)
            let response = try await networkService.executeWithRetry(request)
            return response.data
        } else {
            let products: [Product] = try await mockNetworkService.simulateRequest(
                endpoint: "/products" + (category != nil ? "?category=\(category!)" : ""),
                responseType: [Product].self
            )
            return products
        }
    }
    
    func fetchProduct(id: String) async throws -> Product {
        if useRealAPI {
            let request = ProductDetailRequest(productId: id)
            let response = try await networkService.executeWithRetry(request)
            return response.data
        } else {
            let product: Product = try await mockNetworkService.simulateRequest(
                endpoint: "/products/\(id)",
                responseType: Product.self
            )
            return product
        }
    }
    
    func searchProducts(query: String, category: String? = nil, limit: Int? = nil) async throws -> [Product] {
        if useRealAPI {
            let request = ProductSearchRequest(query: query, category: category, limit: limit)
            let response = try await networkService.executeWithRetry(request)
            return response.data
        } else {
            let products: [Product] = try await mockNetworkService.simulateRequest(
                endpoint: "/products/search?q=\(query)",
                responseType: [Product].self
            )
            return products
        }
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        if useRealAPI {
            let request = LoginRequest(email: email, password: password)
            let response = try await networkService.executeWithRetry(request)
            return response.data
        } else {
            let user = mockDataService.mockLogin(email: email, password: password)
            return AuthResponse(
                user: user,
                accessToken: "mock_access_token_\(UUID().uuidString)",
                refreshToken: "mock_refresh_token_\(UUID().uuidString)",
                expiresIn: 3600
            )
        }
    }
    
    func getCurrentUser() async throws -> User? {
        if useRealAPI {
            do {
                let request = UserProfileRequest()
                let response = try await networkService.execute(request)
                return response.data
            } catch let error as NetworkError where error.statusCode == 401 {
                return nil
            }
        } else {
            return mockDataService.getCurrentUser()
        }
    }
    
    func toggleAPIMode() {
        useRealAPI.toggle()
    }
}

struct UserProfileRequest: NetworkRequest {
    typealias ResponseType = User
    
    let path = "/user/profile"
    let method = HTTPMethod.GET
    
    var headers: HTTPHeaders {
        var headers = HTTPHeaders.default
        if let token = AuthTokenManager.shared.getCurrentAccessToken() {
            headers.add(name: "Authorization", value: "Bearer \(token)")
        }
        return headers
    }
}

class AuthTokenManager: ObservableObject {
    static let shared = AuthTokenManager()
    
    @Published var accessToken: String?
    @Published var refreshToken: String?
    @Published var isAuthenticated: Bool = false
    
    private let keychain = KeychainManager()
    private let queue = DispatchQueue(label: "AuthTokenManager", attributes: .concurrent)
    
    private init() {
        loadTokens()
    }
    
    func saveTokens(access: String, refresh: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.keychain.save(key: "access_token", value: access)
            self.keychain.save(key: "refresh_token", value: refresh)
            
            DispatchQueue.main.async {
                self.accessToken = access
                self.refreshToken = refresh
                self.isAuthenticated = true
            }
        }
    }
    
    func clearTokens() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.keychain.delete(key: "access_token")
            self.keychain.delete(key: "refresh_token")
            
            DispatchQueue.main.async {
                self.accessToken = nil
                self.refreshToken = nil
                self.isAuthenticated = false
            }
        }
    }
    
    private func loadTokens() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let access = self.keychain.load(key: "access_token")
            let refresh = self.keychain.load(key: "refresh_token")
            
            DispatchQueue.main.async {
                self.accessToken = access
                self.refreshToken = refresh
                self.isAuthenticated = access != nil
            }
        }
    }
    
    func getCurrentAccessToken() -> String? {
        return accessToken
    }
}

class KeychainManager {
    func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}