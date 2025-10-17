import Foundation
import Combine
import EmbraceIO
import OpenTelemetryApi

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()

    @Published var isLoading = false
    @Published var useRealAPI = false

    private let networkService = NetworkService.shared
    private let mockNetworkService = MockNetworkService.shared
    private let mockDataService = MockDataService.shared
    private let embraceService = EmbraceService.shared

    private init() {}
    
    func fetchProducts(category: String? = nil, limit: Int? = nil, offset: Int? = nil) async throws -> [Product] {
        let span = Embrace.client?.buildSpan(name: "api_fetch_products", type: .performance).startSpan()
        span?.setAttribute(key: "api.method", value: "fetchProducts")
        span?.setAttribute(key: "api.use_real_api", value: String(useRealAPI))
        if let category = category {
            span?.setAttribute(key: "api.category", value: category)
        }
        if let limit = limit {
            span?.setAttribute(key: "api.limit", value: String(limit))
        }
        if let offset = offset {
            span?.setAttribute(key: "api.offset", value: String(offset))
        }

        let startTime = Date()

        do {
            let products: [Product]
            if useRealAPI {
                let request = ProductsRequest(category: category, limit: limit, offset: offset)
                let response = try await networkService.executeWithRetry(request)
                products = response.data
            } else {
                products = try await mockNetworkService.simulateRequest(
                    endpoint: "/products" + (category != nil ? "?category=\(category!)" : ""),
                    responseType: [Product].self
                )
            }

            let duration = Date().timeIntervalSince(startTime)
            span?.setAttribute(key: "api.result_count", value: String(products.count))
            span?.setAttribute(key: "api.duration_ms", value: String(Int(duration * 1000)))
            span?.end()

            embraceService.logInfo("Products fetched successfully", properties: [
                "api.method": "fetchProducts",
                "api.use_real_api": String(useRealAPI),
                "api.category": category ?? "all",
                "api.result_count": String(products.count),
                "api.duration_ms": String(Int(duration * 1000))
            ])

            return products
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            span?.setAttribute(key: "error.type", value: String(describing: type(of: error)))
            span?.setAttribute(key: "error.message", value: error.localizedDescription)
            span?.setAttribute(key: "api.duration_ms", value: String(Int(duration * 1000)))
            span?.end(errorCode: .failure)

            embraceService.logError("Failed to fetch products", properties: [
                "api.method": "fetchProducts",
                "api.use_real_api": String(useRealAPI),
                "api.category": category ?? "all",
                "error.type": String(describing: type(of: error)),
                "error.message": error.localizedDescription,
                "api.duration_ms": String(Int(duration * 1000))
            ])

            throw error
        }
    }
    
    func fetchProduct(id: String) async throws -> Product {
        let span = Embrace.client?.buildSpan(name: "api_fetch_product_detail", type: .performance).startSpan()
        span?.setAttribute(key: "api.method", value: "fetchProduct")
        span?.setAttribute(key: "api.use_real_api", value: String(useRealAPI))
        span?.setAttribute(key: "api.product_id", value: id)

        let startTime = Date()

        do {
            let product: Product
            if useRealAPI {
                let request = ProductDetailRequest(productId: id)
                let response = try await networkService.executeWithRetry(request)
                product = response.data
            } else {
                product = try await mockNetworkService.simulateRequest(
                    endpoint: "/products/\(id)",
                    responseType: Product.self
                )
            }

            let duration = Date().timeIntervalSince(startTime)
            span?.setAttribute(key: "api.product_name", value: product.name)
            span?.setAttribute(key: "api.product_category", value: product.category)
            span?.setAttribute(key: "api.duration_ms", value: String(Int(duration * 1000)))
            span?.end()

            embraceService.logInfo("Product detail fetched successfully", properties: [
                "api.method": "fetchProduct",
                "api.use_real_api": String(useRealAPI),
                "api.product_id": id,
                "api.product_name": product.name,
                "api.duration_ms": String(Int(duration * 1000))
            ])

            return product
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            span?.setAttribute(key: "error.type", value: String(describing: type(of: error)))
            span?.setAttribute(key: "error.message", value: error.localizedDescription)
            span?.setAttribute(key: "api.duration_ms", value: String(Int(duration * 1000)))
            span?.end(errorCode: .failure)

            embraceService.logError("Failed to fetch product detail", properties: [
                "api.method": "fetchProduct",
                "api.use_real_api": String(useRealAPI),
                "api.product_id": id,
                "error.type": String(describing: type(of: error)),
                "error.message": error.localizedDescription,
                "api.duration_ms": String(Int(duration * 1000))
            ])

            throw error
        }
    }

    func searchProducts(query: String, category: String? = nil, limit: Int? = nil) async throws -> [Product] {
        let span = Embrace.client?.buildSpan(name: "api_search_products", type: .performance).startSpan()
        span?.setAttribute(key: "api.method", value: "searchProducts")
        span?.setAttribute(key: "api.use_real_api", value: String(useRealAPI))
        span?.setAttribute(key: "api.search_query", value: query)
        if let category = category {
            span?.setAttribute(key: "api.category", value: category)
        }
        if let limit = limit {
            span?.setAttribute(key: "api.limit", value: String(limit))
        }

        let startTime = Date()

        do {
            let products: [Product]
            if useRealAPI {
                let request = ProductSearchRequest(query: query, category: category, limit: limit)
                let response = try await networkService.executeWithRetry(request)
                products = response.data
            } else {
                products = try await mockNetworkService.simulateRequest(
                    endpoint: "/products/search?q=\(query)",
                    responseType: [Product].self
                )
            }

            let duration = Date().timeIntervalSince(startTime)
            span?.setAttribute(key: "api.result_count", value: String(products.count))
            span?.setAttribute(key: "api.duration_ms", value: String(Int(duration * 1000)))
            span?.end()

            embraceService.logInfo("Product search completed successfully", properties: [
                "api.method": "searchProducts",
                "api.use_real_api": String(useRealAPI),
                "api.search_query": query,
                "api.category": category ?? "all",
                "api.result_count": String(products.count),
                "api.duration_ms": String(Int(duration * 1000))
            ])

            return products
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            span?.setAttribute(key: "error.type", value: String(describing: type(of: error)))
            span?.setAttribute(key: "error.message", value: error.localizedDescription)
            span?.setAttribute(key: "api.duration_ms", value: String(Int(duration * 1000)))
            span?.end(errorCode: .failure)

            embraceService.logError("Product search failed", properties: [
                "api.method": "searchProducts",
                "api.use_real_api": String(useRealAPI),
                "api.search_query": query,
                "api.category": category ?? "all",
                "error.type": String(describing: type(of: error)),
                "error.message": error.localizedDescription,
                "api.duration_ms": String(Int(duration * 1000))
            ])

            throw error
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