import Foundation
import UIKit

@MainActor
class StripePaymentService: ObservableObject {
    static let shared = StripePaymentService()
    
    private let publishableKey = "pk_test_51Oe1X3Eep9vPfqZwLUKPzwMXNaTGNE8jGcHPt9M4Vt3XrHMG4iGJo8JTk0y8FEO9eMpG1w6H3v4QRhNvL5XK8X00ABC123DE"
    private let secretKey = "sk_test_51Oe1X3Eep9vPfqZwLUKPzwMXNaTGNE8jGcHPt9M4Vt3XrHMG4iGJo8JTk0y8FEO9eMpG1w6H3v4QRhNvL5XK8X00ABC123DE"
    
    @Published var paymentResult: StripePaymentResult?
    @Published var isProcessing = false
    
    private init() {
        // Stripe setup - in real implementation would configure Stripe SDK
        print("✅ Stripe Test Environment Initialized")
    }
    
    func processPayment(amount: Double, currency: String = "usd") async -> Result<StripePaymentResult, StripePaymentError> {
        guard amount > 0 else {
            return .failure(.invalidAmount)
        }
        
        guard amount >= 0.50 else {
            return .failure(.amountTooSmall)
        }
        
        await MainActor.run {
            isProcessing = true
        }
        
        do {
            let paymentIntent = try await createPaymentIntent(amount: amount, currency: currency)
            
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            let result = StripePaymentResult(
                paymentIntentId: paymentIntent.id,
                status: .succeeded,
                amount: amount,
                currency: currency,
                paymentMethodId: "pm_test_\(UUID().uuidString.prefix(12))"
            )
            
            await MainActor.run {
                paymentResult = result
                isProcessing = false
            }
            
            return .success(result)
        } catch {
            await MainActor.run {
                isProcessing = false
            }
            return .failure(.paymentFailed(error))
        }
    }
    
    private func createPaymentIntent(amount: Double, currency: String) async throws -> MockPaymentIntent {
        let amountInCents = Int(amount * 100)
        
        let random = Double.random(in: 0...1)
        if random < 0.05 {
            throw StripePaymentError.paymentIntentCreationFailed
        }
        
        return MockPaymentIntent(
            id: "pi_test_\(UUID().uuidString.prefix(16))",
            amount: amountInCents,
            currency: currency,
            status: "requires_payment_method"
        )
    }
    
    func simulatePaymentFailure() async -> Result<StripePaymentResult, StripePaymentError> {
        await MainActor.run {
            isProcessing = true
        }
        
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        await MainActor.run {
            isProcessing = false
        }
        
        return .failure(.paymentFailed(NSError(domain: "StripeError", code: 4000, userInfo: [NSLocalizedDescriptionKey: "Your card was declined."])))
    }
}

struct MockPaymentIntent {
    let id: String
    let amount: Int
    let currency: String
    let status: String
}

struct StripePaymentResult {
    let paymentIntentId: String
    let status: StripePaymentStatus
    let amount: Double
    let currency: String
    let paymentMethodId: String
    
    enum StripePaymentStatus: String {
        case succeeded = "succeeded"
        case failed = "failed"
        case cancelled = "cancelled"
        case requiresAction = "requires_action"
    }
}

enum StripePaymentError: Error, LocalizedError {
    case invalidAmount
    case amountTooSmall
    case paymentIntentCreationFailed
    case paymentFailed(Error)
    case networkError(Error)
    case configurationError
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Invalid payment amount"
        case .amountTooSmall:
            return "Payment amount must be at least $0.50"
        case .paymentIntentCreationFailed:
            return "Failed to create payment intent"
        case .paymentFailed(let error):
            return "Payment failed: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .configurationError:
            return "Payment configuration error"
        }
    }
}

struct StripeTestCards {
    static let visaSuccess = "4242424242424242"
    static let visaDeclined = "4000000000000002"
    static let mastercardSuccess = "5555555555554444"
    static let amexSuccess = "378282246310005"
    static let chargeCustomerFail = "4000000000000341"
    static let authenticationRequired = "4000002500003155"
    
    static let allTestCards = [
        ("Visa (Success)", visaSuccess),
        ("Visa (Declined)", visaDeclined),
        ("Mastercard (Success)", mastercardSuccess),
        ("Amex (Success)", amexSuccess),
        ("Charge Customer Fail", chargeCustomerFail),
        ("Authentication Required", authenticationRequired)
    ]
}