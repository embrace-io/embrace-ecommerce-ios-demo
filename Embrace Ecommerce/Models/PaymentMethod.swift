import Foundation

struct PaymentMethod: Codable, Identifiable {
    let id: String
    let type: PaymentType
    let isDefault: Bool
    let cardInfo: CardInfo?
    let digitalWalletInfo: DigitalWalletInfo?
    let stripePaymentMethodId: String?
    
    enum PaymentType: String, Codable {
        case creditCard = "credit_card"
        case debitCard = "debit_card"
        case applePay = "apple_pay"
        case paypal = "paypal"
        case stripe = "stripe"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type
        case isDefault = "is_default"
        case cardInfo = "card_info"
        case digitalWalletInfo = "digital_wallet_info"
        case stripePaymentMethodId = "stripe_payment_method_id"
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

struct PaymentTransaction: Codable, Identifiable {
    let id: String
    let paymentIntentId: String?
    let amount: Double
    let currency: String
    let status: PaymentStatus
    let createdAt: Date
    let paymentMethodUsed: PaymentMethod
    let failureReason: String?
    
    enum PaymentStatus: String, Codable {
        case pending = "pending"
        case succeeded = "succeeded"
        case failed = "failed"
        case cancelled = "cancelled"
        case requiresAction = "requires_action"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case paymentIntentId = "payment_intent_id"
        case amount, currency, status
        case createdAt = "created_at"
        case paymentMethodUsed = "payment_method_used"
        case failureReason = "failure_reason"
    }
}