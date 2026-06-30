import Foundation
import Combine
import EmbraceIO

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
    private let embraceService = EmbraceService.shared
    
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

        // Create Embrace span for network request
        let span = EmbraceIO.shared.createSpan(name: "network_request", type: .networkRequest)
        try? span?.setAttribute(key: "http.method", value: request.method.rawValue)
        try? span?.setAttribute(key: "http.path", value: request.path)
        try? span?.setAttribute(key: "request.id", value: requestId.uuidString)

        guard reachability.isConnected else {
            try? span?.setAttribute(key: "error.type", value: "network_unavailable")
            span?.end(errorCode: .failure)
            embraceService.logError("Network request failed - No internet connection", properties: [
                "request.id": requestId.uuidString,
                "http.path": request.path,
                "http.method": request.method.rawValue
            ])
            throw NetworkError.networkUnavailable
        }

        guard let urlRequest = request.urlRequest else {
            try? span?.setAttribute(key: "error.type", value: "invalid_url")
            span?.end(errorCode: .failure)
            embraceService.logError("Network request failed - Invalid URL", properties: [
                "request.id": requestId.uuidString,
                "http.path": request.path
            ])
            throw NetworkError.invalidURL
        }

        try? span?.setAttribute(key: "http.url", value: urlRequest.url?.absoluteString ?? "unknown")

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
            let duration = endTime.timeIntervalSince(startTime)

            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NetworkError.invalidResponse
                requestMetrics[requestId]?.error = error
                requestMetrics[requestId]?.endTime = endTime

                try? span?.setAttribute(key: "error.type", value: "invalid_response")
                try? span?.setAttribute(key: "duration_ms", value: String(Int(duration * 1000)))
                span?.end(errorCode: .failure)

                embraceService.logError("Network request failed - Invalid response", properties: [
                    "request.id": requestId.uuidString,
                    "http.path": request.path,
                    "duration_ms": String(Int(duration * 1000))
                ])

                throw error
            }

            requestMetrics[requestId]?.statusCode = httpResponse.statusCode
            requestMetrics[requestId]?.endTime = endTime

            try? span?.setAttribute(key: "http.status_code", value: String(httpResponse.statusCode))
            try? span?.setAttribute(key: "http.response_size_bytes", value: String(data.count))
            try? span?.setAttribute(key: "duration_ms", value: String(Int(duration * 1000)))

            logResponse(httpResponse, data: data, id: requestId)

            if 200..<300 ~= httpResponse.statusCode {
                let decodedData = try jsonDecoder.decode(T.ResponseType.self, from: data)

                let apiResponse = APIResponse<T.ResponseType>(
                    data: decodedData,
                    statusCode: httpResponse.statusCode,
                    headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
                    responseTime: duration
                )

                span?.end()

                embraceService.logInfo("Network request successful", properties: [
                    "request.id": requestId.uuidString,
                    "http.path": request.path,
                    "http.method": request.method.rawValue,
                    "http.status_code": String(httpResponse.statusCode),
                    "duration_ms": String(Int(duration * 1000)),
                    "response_size_bytes": String(data.count)
                ])

                return apiResponse
            } else {
                let error = NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
                requestMetrics[requestId]?.error = error

                try? span?.setAttribute(key: "error.type", value: "http_error")
                try? span?.setAttribute(key: "error.status_code", value: String(httpResponse.statusCode))
                span?.end(errorCode: .failure)

                embraceService.logError("Network request failed - HTTP error", properties: [
                    "request.id": requestId.uuidString,
                    "http.path": request.path,
                    "http.method": request.method.rawValue,
                    "http.status_code": String(httpResponse.statusCode),
                    "duration_ms": String(Int(duration * 1000))
                ])

                throw error
            }

        } catch {
            let networkError = NetworkError.from(error)
            requestMetrics[requestId]?.error = networkError
            requestMetrics[requestId]?.endTime = Date()

            let duration = Date().timeIntervalSince(startTime)
            try? span?.setAttribute(key: "error.type", value: String(describing: type(of: networkError)))
            try? span?.setAttribute(key: "error.message", value: networkError.localizedDescription)
            try? span?.setAttribute(key: "duration_ms", value: String(Int(duration * 1000)))
            span?.end(errorCode: .failure)

            logError(networkError, id: requestId)

            embraceService.logError("Network request failed", properties: [
                "request.id": requestId.uuidString,
                "http.path": request.path,
                "http.method": request.method.rawValue,
                "error.type": String(describing: type(of: networkError)),
                "error.message": networkError.localizedDescription,
                "duration_ms": String(Int(duration * 1000))
            ])

            throw networkError
        }
    }
    
    func executeWithRetry<T: NetworkRequest>(
        _ request: T,
        maxRetries: Int = 3,
        delay: TimeInterval = 1.0
    ) async throws -> APIResponse<T.ResponseType> {
        var lastError: NetworkError?

        let retrySpan = EmbraceIO.shared.createSpan(name: "network_request_with_retry", type: .performance)
        try? retrySpan?.setAttribute(key: "http.method", value: request.method.rawValue)
        try? retrySpan?.setAttribute(key: "http.path", value: request.path)
        try? retrySpan?.setAttribute(key: "retry.max_attempts", value: String(maxRetries + 1))

        for attempt in 0...maxRetries {
            try? retrySpan?.setAttribute(key: "retry.current_attempt", value: String(attempt + 1))

            do {
                let response = try await execute(request)
                try? retrySpan?.setAttribute(key: "retry.succeeded", value: "true")
                try? retrySpan?.setAttribute(key: "retry.attempts_used", value: String(attempt + 1))
                retrySpan?.end()

                if attempt > 0 {
                    embraceService.logInfo("Network request succeeded after retry", properties: [
                        "http.path": request.path,
                        "http.method": request.method.rawValue,
                        "retry.attempts": String(attempt + 1),
                        "retry.max_attempts": String(maxRetries + 1)
                    ])
                }

                return response
            } catch let error as NetworkError {
                lastError = error

                if attempt < maxRetries && error.isRetryable {
                    let backoffDelay = delay * pow(2.0, Double(attempt))
                    try? retrySpan?.setAttribute(key: "retry.delay_ms", value: String(Int(backoffDelay * 1000)))

                    embraceService.logWarning("Network request failed, retrying", properties: [
                        "http.path": request.path,
                        "http.method": request.method.rawValue,
                        "retry.attempt": String(attempt + 1),
                        "retry.max_attempts": String(maxRetries + 1),
                        "retry.backoff_delay_ms": String(Int(backoffDelay * 1000)),
                        "error.message": error.localizedDescription
                    ])

                    try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                    continue
                } else {
                    try? retrySpan?.setAttribute(key: "retry.succeeded", value: "false")
                    try? retrySpan?.setAttribute(key: "retry.attempts_used", value: String(attempt + 1))
                    try? retrySpan?.setAttribute(key: "error.message", value: error.localizedDescription)
                    retrySpan?.end(errorCode: .failure)

                    embraceService.logError("Network request failed after all retries", properties: [
                        "http.path": request.path,
                        "http.method": request.method.rawValue,
                        "retry.attempts": String(attempt + 1),
                        "retry.max_attempts": String(maxRetries + 1),
                        "error.message": error.localizedDescription,
                        "error.is_retryable": String(error.isRetryable)
                    ])

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