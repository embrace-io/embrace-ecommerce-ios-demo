import Foundation
import Combine

protocol NetworkServiceProtocol {
    func execute<T: NetworkRequest>(_ request: T) async throws -> APIResponse<T.ResponseType>
}

@MainActor
class NetworkService: NetworkServiceProtocol, ObservableObject {
    static let shared = NetworkService()
    
    @Published var isLoading = false
    @Published var activeRequests = Set<UUID>()
    
    private let session: URLSession
    private let reachability = NetworkReachability.shared
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    private var requestMetrics: [UUID: RequestMetrics] = [:]
    
    struct RequestMetrics {
        let id: UUID
        let startTime: Date
        let endpoint: String
        let method: String
        var endTime: Date?
        var statusCode: Int?
        var error: NetworkError?
        
        var duration: TimeInterval? {
            guard let endTime = endTime else { return nil }
            return endTime.timeIntervalSince(startTime)
        }
    }
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,
            diskCapacity: 50 * 1024 * 1024,
            diskPath: "network_cache"
        )
        
        session = URLSession(configuration: config)
        
        setupJSONDecoder()
    }
    
    private func setupJSONDecoder() {
        jsonDecoder.dateDecodingStrategy = .iso8601
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    func execute<T: NetworkRequest>(_ request: T) async throws -> APIResponse<T.ResponseType> {
        let requestId = UUID()
        let startTime = Date()
        
        guard reachability.isConnected else {
            throw NetworkError.networkUnavailable
        }
        
        guard let urlRequest = request.urlRequest else {
            throw NetworkError.invalidURL
        }
        
        let metrics = RequestMetrics(
            id: requestId,
            startTime: startTime,
            endpoint: request.path,
            method: request.method.rawValue
        )
        
        requestMetrics[requestId] = metrics
        activeRequests.insert(requestId)
        isLoading = !activeRequests.isEmpty
        
        defer {
            activeRequests.remove(requestId)
            isLoading = !activeRequests.isEmpty
        }
        
        do {
            logRequest(urlRequest, id: requestId)
            
            let (data, response) = try await session.data(for: urlRequest)
            let endTime = Date()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NetworkError.invalidResponse
                requestMetrics[requestId]?.error = error
                requestMetrics[requestId]?.endTime = endTime
                throw error
            }
            
            requestMetrics[requestId]?.statusCode = httpResponse.statusCode
            requestMetrics[requestId]?.endTime = endTime
            
            logResponse(httpResponse, data: data, id: requestId)
            
            if 200..<300 ~= httpResponse.statusCode {
                let decodedData = try jsonDecoder.decode(T.ResponseType.self, from: data)
                
                let apiResponse = APIResponse<T.ResponseType>(
                    data: decodedData,
                    statusCode: httpResponse.statusCode,
                    headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
                    responseTime: endTime.timeIntervalSince(startTime)
                )
                
                return apiResponse
            } else {
                let error = NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
                requestMetrics[requestId]?.error = error
                throw error
            }
            
        } catch {
            let networkError = NetworkError.from(error)
            requestMetrics[requestId]?.error = networkError
            requestMetrics[requestId]?.endTime = Date()
            logError(networkError, id: requestId)
            throw networkError
        }
    }
    
    func executeWithRetry<T: NetworkRequest>(
        _ request: T,
        maxRetries: Int = 3,
        delay: TimeInterval = 1.0
    ) async throws -> APIResponse<T.ResponseType> {
        var lastError: NetworkError?
        
        for attempt in 0...maxRetries {
            do {
                return try await execute(request)
            } catch let error as NetworkError {
                lastError = error
                
                if attempt < maxRetries && error.isRetryable {
                    let backoffDelay = delay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                    continue
                } else {
                    throw error
                }
            }
        }
        
        throw lastError ?? NetworkError.unknown(NSError(domain: "NetworkService", code: -1))
    }
    
    func cancelAllRequests() {
        session.invalidateAndCancel()
        activeRequests.removeAll()
        isLoading = false
    }
    
    func getMetrics() -> [RequestMetrics] {
        Array(requestMetrics.values).sorted { $0.startTime > $1.startTime }
    }
    
    func clearMetrics() {
        requestMetrics.removeAll()
    }
    
    private func logRequest(_ request: URLRequest, id: UUID) {
        print("🌐 [REQUEST \(id.uuidString.prefix(8))] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "unknown")")
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("📋 Headers: \(headers)")
        }
        
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("📦 Body: \(bodyString)")
        }
    }
    
    private func logResponse(_ response: HTTPURLResponse, data: Data, id: UUID) {
        let statusEmoji = response.statusCode < 300 ? "✅" : "❌"
        print("\(statusEmoji) [RESPONSE \(id.uuidString.prefix(8))] \(response.statusCode) - \(data.count) bytes")
        
        if let responseString = String(data: data, encoding: .utf8), data.count < 1000 {
            print("📥 Response: \(responseString)")
        }
    }
    
    private func logError(_ error: NetworkError, id: UUID) {
        print("🔥 [ERROR \(id.uuidString.prefix(8))] \(error.localizedDescription)")
    }
}

extension NetworkService {
    convenience init(mockSession: URLSession) {
        self.init()
    }
}