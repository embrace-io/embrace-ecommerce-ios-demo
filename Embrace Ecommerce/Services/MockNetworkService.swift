import Foundation
import Combine

enum MockNetworkResponse {
    case success
    case failure(MockNetworkError)
    case slow
}

enum MockNetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    case serverError(code: Int)
    case invalidData
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverError(let code):
            return "Server error (\(code))"
        case .invalidData:
            return "Invalid response data"
        case .notFound:
            return "Resource not found"
        }
    }
}

struct MockNetworkConfig {
    var baseDelay: TimeInterval = 0.5
    var slowDelay: TimeInterval = 3.0
    var failureRate: Double = 0.1
    var timeoutRate: Double = 0.05
    var serverErrorRate: Double = 0.05
    
    static let `default` = MockNetworkConfig()
    static let fast = MockNetworkConfig(baseDelay: 0.1, slowDelay: 1.0)
    static let slow = MockNetworkConfig(baseDelay: 2.0, slowDelay: 5.0)
    static let unreliable = MockNetworkConfig(
        baseDelay: 1.0,
        slowDelay: 4.0,
        failureRate: 0.3,
        timeoutRate: 0.2,
        serverErrorRate: 0.1
    )
}

@MainActor
class MockNetworkService: ObservableObject {
    static let shared = MockNetworkService()
    
    @Published var config = MockNetworkConfig.default
    @Published var isOnline = true
    
    private init() {}
    
    func simulateRequest<T: Codable>(
        endpoint: String,
        responseType: T.Type,
        scenario: MockNetworkResponse? = nil
    ) async throws -> T {
        let actualScenario = scenario ?? determineResponseScenario()
        
        try await simulateNetworkDelay(for: actualScenario)
        
        switch actualScenario {
        case .success:
            return try await handleSuccessResponse(endpoint: endpoint, responseType: responseType)
        case .failure(let error):
            throw error
        case .slow:
            try await simulateNetworkDelay(for: .success)
            return try await handleSuccessResponse(endpoint: endpoint, responseType: responseType)
        }
    }
    
    private func determineResponseScenario() -> MockNetworkResponse {
        if !isOnline {
            return .failure(.noConnection)
        }
        
        let random = Double.random(in: 0...1)
        
        if random < config.timeoutRate {
            return .failure(.timeout)
        } else if random < config.timeoutRate + config.serverErrorRate {
            let errorCode = [500, 502, 503, 504].randomElement() ?? 500
            return .failure(.serverError(code: errorCode))
        } else if random < config.timeoutRate + config.serverErrorRate + config.failureRate {
            return .failure(.invalidData)
        } else if random < config.timeoutRate + config.serverErrorRate + config.failureRate + 0.2 {
            return .slow
        }
        
        return .success
    }
    
    private func simulateNetworkDelay(for scenario: MockNetworkResponse) async throws {
        let delay: TimeInterval
        
        switch scenario {
        case .success:
            delay = config.baseDelay + Double.random(in: 0...0.5)
        case .slow:
            delay = config.slowDelay + Double.random(in: 0...1.0)
        case .failure:
            delay = config.baseDelay * 0.3
        }
        
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
    
    private func handleSuccessResponse<T: Codable>(
        endpoint: String,
        responseType: T.Type
    ) async throws -> T {
        switch endpoint {
        case "/products/featured":
            if let products = MockDataService.shared.getFeaturedProducts() as? T {
                return products
            }
        case let path where path.starts(with: "/products/search"):
            let query = extractQueryParameter(from: path, parameter: "q") ?? ""
            if let results = MockDataService.shared.searchProducts(query: query) as? T {
                return results
            }
        case let path where path.starts(with: "/products/category"):
            let category = extractQueryParameter(from: path, parameter: "category")
            if let products = MockDataService.shared.getProducts(for: category) as? T {
                return products
            }
        case let path where path.starts(with: "/products/"):
            let productId = String(path.dropFirst("/products/".count))
            if let product = MockDataService.shared.getProduct(by: productId) as? T {
                return product
            } else {
                throw MockNetworkError.notFound
            }
        case "/auth/login":
            if let user = MockDataService.shared.mockLogin() as? T {
                return user
            }
        case "/user/profile":
            if let user = MockDataService.shared.getCurrentUser() as? T {
                return user
            }
        default:
            break
        }
        
        throw MockNetworkError.invalidData
    }
    
    private func extractQueryParameter(from path: String, parameter: String) -> String? {
        guard let url = URLComponents(string: path),
              let queryItems = url.queryItems else {
            return nil
        }
        return queryItems.first { $0.name == parameter }?.value
    }
}

extension MockNetworkService {
    func setNetworkCondition(_ condition: NetworkCondition) {
        switch condition {
        case .optimal:
            config = .fast
            isOnline = true
        case .normal:
            config = .default
            isOnline = true
        case .poor:
            config = .slow
            isOnline = true
        case .unreliable:
            config = .unreliable
            isOnline = true
        case .offline:
            isOnline = false
        }
    }
}

enum NetworkCondition: String, CaseIterable {
    case optimal = "Optimal"
    case normal = "Normal"
    case poor = "Poor"
    case unreliable = "Unreliable"
    case offline = "Offline"
    
    var description: String {
        switch self {
        case .optimal:
            return "Fast, reliable connection"
        case .normal:
            return "Standard connection speed"
        case .poor:
            return "Slow but stable connection"
        case .unreliable:
            return "Frequent failures and timeouts"
        case .offline:
            return "No network connection"
        }
    }
}