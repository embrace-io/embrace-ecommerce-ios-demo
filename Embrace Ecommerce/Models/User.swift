import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let phoneNumber: String?
    let dateJoined: Date
    let isGuest: Bool
    let preferences: UserPreferences?
    
    enum CodingKeys: String, CodingKey {
        case id, email, preferences
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneNumber = "phone_number"
        case dateJoined = "date_joined"
        case isGuest = "is_guest"
    }
}

struct UserPreferences: Codable {
    let newsletter: Bool
    let pushNotifications: Bool
    let biometricAuth: Bool
    let preferredCurrency: String
    
    enum CodingKeys: String, CodingKey {
        case newsletter
        case pushNotifications = "push_notifications"
        case biometricAuth = "biometric_auth"
        case preferredCurrency = "preferred_currency"
    }
}