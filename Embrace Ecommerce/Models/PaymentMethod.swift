import Foundation

struct PaymentMethod: Codable, Identifiable {
    let id: String
    let type: PaymentType
    let isDefault: Bool
    let cardInfo: CardInfo?
    let digitalWalletInfo: DigitalWalletInfo?
    
    enum PaymentType: String, Codable {
        case creditCard = "credit_card"
        case debitCard = "debit_card"
        case applePay = "apple_pay"
        case paypal = "paypal"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type
        case isDefault = "is_default"
        case cardInfo = "card_info"
        case digitalWalletInfo = "digital_wallet_info"
    }
}

struct CardInfo: Codable {
    let last4: String
    let brand: String
    let expiryMonth: Int
    let expiryYear: Int
    let holderName: String
    
    var displayName: String {
        return "\(brand.capitalized) ••••\(last4)"
    }
    
    enum CodingKeys: String, CodingKey {
        case last4, brand
        case expiryMonth = "expiry_month"
        case expiryYear = "expiry_year"
        case holderName = "holder_name"
    }
}

struct DigitalWalletInfo: Codable {
    let email: String?
    let displayName: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case displayName = "display_name"
    }
}