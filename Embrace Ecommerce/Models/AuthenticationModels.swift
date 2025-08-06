import Foundation

// MARK: - Authentication State
enum AuthenticationState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(AuthenticatedUser)
    case biometricRequired(PendingUser)
    case error(AuthenticationError)
}

// MARK: - Authentication Method
enum AuthenticationMethod: String, CaseIterable {
    case email = "email"
    case google = "google"
    case guest = "guest"
    case biometric = "biometric"
    
    var displayName: String {
        switch self {
        case .email:
            return "Email & Password"
        case .google:
            return "Google Sign-In"
        case .guest:
            return "Continue as Guest"
        case .biometric:
            return "Face ID / Touch ID"
        }
    }
    
    var iconName: String {
        switch self {
        case .email:
            return "envelope.fill"
        case .google:
            return "globe"
        case .guest:
            return "person.crop.circle"
        case .biometric:
            return "faceid"
        }
    }
}

// MARK: - Authentication Errors
enum AuthenticationError: Error, LocalizedError, Equatable {
    case invalidCredentials
    case networkError
    case biometricNotAvailable
    case biometricFailed
    case googleSignInFailed(String)
    case userCancelled
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection error"
        case .biometricNotAvailable:
            return "Biometric authentication is not available"
        case .biometricFailed:
            return "Biometric authentication failed"
        case .googleSignInFailed(let message):
            return "Google Sign-In failed: \(message)"
        case .userCancelled:
            return "Authentication was cancelled"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - User Types
struct AuthenticatedUser: Codable, Equatable {
    let id: String
    let email: String
    let displayName: String
    let photoURL: String?
    let authMethod: AuthenticationMethod
    let createdAt: Date
    let lastSignInAt: Date
    let isGuest: Bool
    let biometricEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, email, displayName, photoURL, authMethod, createdAt, lastSignInAt, isGuest, biometricEnabled
    }
    
    init(id: String, email: String, displayName: String, photoURL: String?, authMethod: AuthenticationMethod, createdAt: Date, lastSignInAt: Date, isGuest: Bool, biometricEnabled: Bool) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.authMethod = authMethod
        self.createdAt = createdAt
        self.lastSignInAt = lastSignInAt
        self.isGuest = isGuest
        self.biometricEnabled = biometricEnabled
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        
        if let authMethodString = try? container.decode(String.self, forKey: .authMethod),
           let decodedAuthMethod = AuthenticationMethod(rawValue: authMethodString) {
            authMethod = decodedAuthMethod
        } else {
            authMethod = .email // Default fallback
        }
        
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastSignInAt = try container.decode(Date.self, forKey: .lastSignInAt)
        isGuest = try container.decode(Bool.self, forKey: .isGuest)
        biometricEnabled = try container.decode(Bool.self, forKey: .biometricEnabled)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(photoURL, forKey: .photoURL)
        try container.encode(authMethod.rawValue, forKey: .authMethod)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastSignInAt, forKey: .lastSignInAt)
        try container.encode(isGuest, forKey: .isGuest)
        try container.encode(biometricEnabled, forKey: .biometricEnabled)
    }
}

struct PendingUser: Codable, Equatable {
    let email: String
    let displayName: String
    let photoURL: String?
    let authMethod: AuthenticationMethod
    let tempToken: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        tempToken = try container.decode(String.self, forKey: .tempToken)
        
        if let authMethodString = try? container.decode(String.self, forKey: .authMethod),
           let decodedAuthMethod = AuthenticationMethod(rawValue: authMethodString) {
            authMethod = decodedAuthMethod
        } else {
            authMethod = .email
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(email, forKey: .email)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(photoURL, forKey: .photoURL)
        try container.encode(authMethod.rawValue, forKey: .authMethod)
        try container.encode(tempToken, forKey: .tempToken)
    }
    
    enum CodingKeys: String, CodingKey {
        case email, displayName, photoURL, authMethod, tempToken
    }
}

// MARK: - Authentication Request Models
struct EmailLoginRequest {
    let email: String
    let password: String
}

struct EmailRegistrationRequest {
    let email: String
    let password: String
    let displayName: String
}

// MARK: - Mock Authentication Responses
struct MockAuthResponse: Codable {
    let success: Bool
    let user: AuthenticatedUser?
    let error: String?
    let delay: TimeInterval
    let statusCode: Int
}

// MARK: - Biometric Authentication Types
enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID
    
    var displayName: String {
        switch self {
        case .none:
            return "Not Available"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        }
    }
}

// MARK: - Authentication Session
struct AuthenticationSession: Codable {
    let sessionId: String
    let userId: String
    let authMethod: AuthenticationMethod
    let createdAt: Date
    let expiresAt: Date
    let deviceId: String
    let ipAddress: String?
    
    var isValid: Bool {
        Date() < expiresAt
    }
    
    var timeRemaining: TimeInterval {
        expiresAt.timeIntervalSinceNow
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        userId = try container.decode(String.self, forKey: .userId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        expiresAt = try container.decode(Date.self, forKey: .expiresAt)
        deviceId = try container.decode(String.self, forKey: .deviceId)
        ipAddress = try container.decodeIfPresent(String.self, forKey: .ipAddress)
        
        if let authMethodString = try? container.decode(String.self, forKey: .authMethod),
           let decodedAuthMethod = AuthenticationMethod(rawValue: authMethodString) {
            authMethod = decodedAuthMethod
        } else {
            authMethod = .email
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(userId, forKey: .userId)
        try container.encode(authMethod.rawValue, forKey: .authMethod)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(expiresAt, forKey: .expiresAt)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encodeIfPresent(ipAddress, forKey: .ipAddress)
    }
    
    enum CodingKeys: String, CodingKey {
        case sessionId, userId, authMethod, createdAt, expiresAt, deviceId, ipAddress
    }
}

// MARK: - Authentication Analytics
struct AuthenticationMetrics {
    let method: AuthenticationMethod
    let startTime: Date
    let endTime: Date?
    let success: Bool
    let errorType: String?
    let retryCount: Int
    let biometricUsed: Bool
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}