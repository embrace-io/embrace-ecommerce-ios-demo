import Foundation

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

struct HTTPHeaders {
    private var headers: [String: String] = [:]
    
    init(_ headers: [String: String] = [:]) {
        self.headers = headers
    }
    
    subscript(key: String) -> String? {
        get { headers[key] }
        set { headers[key] = newValue }
    }
    
    mutating func add(name: String, value: String) {
        headers[name] = value
    }
    
    mutating func remove(name: String) {
        headers.removeValue(forKey: name)
    }
    
    var dictionary: [String: String] {
        headers
    }
    
    static var `default`: HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "Accept", value: "application/json")
        return headers
    }
}