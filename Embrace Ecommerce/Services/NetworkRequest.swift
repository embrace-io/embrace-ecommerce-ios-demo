import Foundation

protocol NetworkRequest {
    associatedtype ResponseType: Codable
    
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders { get }
    var queryParameters: [String: String]? { get }
    var body: Data? { get }
    var timeout: TimeInterval { get }
}

extension NetworkRequest {
    var baseURL: String { "https://api.embrace-store.com/v1" }
    var headers: HTTPHeaders { .default }
    var queryParameters: [String: String]? { nil }
    var body: Data? { nil }
    var timeout: TimeInterval { 30.0 }
    
    var urlRequest: URLRequest? {
        guard var urlComponents = URLComponents(string: baseURL + path) else {
            return nil
        }
        
        if let queryParameters = queryParameters {
            urlComponents.queryItems = queryParameters.map { 
                URLQueryItem(name: $0.key, value: $0.value) 
            }
        }
        
        guard let url = urlComponents.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout
        
        for (key, value) in headers.dictionary {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.httpBody = body
        
        return request
    }
}

struct APIResponse<T: Codable> {
    let data: T
    let statusCode: Int
    let headers: [String: String]
    let responseTime: TimeInterval
}

struct EmptyResponse: Codable {}

struct ProductsRequest: NetworkRequest {
    typealias ResponseType = [Product]
    
    let path = "/products"
    let method = HTTPMethod.GET
    let category: String?
    let limit: Int?
    let offset: Int?
    
    var queryParameters: [String: String]? {
        var params: [String: String] = [:]
        
        if let category = category {
            params["category"] = category
        }
        
        if let limit = limit {
            params["limit"] = String(limit)
        }
        
        if let offset = offset {
            params["offset"] = String(offset)
        }
        
        return params.isEmpty ? nil : params
    }
}

struct ProductDetailRequest: NetworkRequest {
    typealias ResponseType = Product
    
    let productId: String
    let method = HTTPMethod.GET
    
    var path: String { "/products/\(productId)" }
}

struct ProductSearchRequest: NetworkRequest {
    typealias ResponseType = [Product]
    
    let query: String
    let category: String?
    let limit: Int?
    
    let path = "/products/search"
    let method = HTTPMethod.GET
    
    var queryParameters: [String: String]? {
        var params = ["q": query]
        
        if let category = category {
            params["category"] = category
        }
        
        if let limit = limit {
            params["limit"] = String(limit)
        }
        
        return params
    }
}

struct LoginRequest: NetworkRequest {
    typealias ResponseType = AuthResponse
    
    let email: String
    let password: String
    
    let path = "/auth/login"
    let method = HTTPMethod.POST
    
    var body: Data? {
        let loginData = LoginData(email: email, password: password)
        return try? JSONEncoder().encode(loginData)
    }
    
    private struct LoginData: Codable {
        let email: String
        let password: String
    }
}

struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}