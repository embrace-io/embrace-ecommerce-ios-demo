import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case networkUnavailable
    case timeout
    case cancelled
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response format"
        case .httpError(let statusCode, _):
            return "HTTP error with status code: \(statusCode)"
        case .networkUnavailable:
            return "Network is unavailable"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .timeout, .networkUnavailable:
            return true
        case .httpError(let statusCode, _):
            return statusCode >= 500 || statusCode == 408 || statusCode == 429
        default:
            return false
        }
    }
    
    var statusCode: Int? {
        switch self {
        case .httpError(let statusCode, _):
            return statusCode
        default:
            return nil
        }
    }
}

extension NetworkError {
    static func from(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .timeout
            case .cancelled:
                return .cancelled
            default:
                return .unknown(urlError)
            }
        }
        
        if error is DecodingError {
            return .decodingError(error)
        }
        
        if error is EncodingError {
            return .encodingError(error)
        }
        
        return .unknown(error)
    }
}