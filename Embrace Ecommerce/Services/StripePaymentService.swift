import Foundation
import UIKit
import Stripe

@MainActor
class StripePaymentService: ObservableObject {
    static let shared = StripePaymentService()
    
    // MARK: - Published Properties
    @Published var paymentResult: StripePaymentResult?
    @Published var isProcessing = false
    
    private init() {
        configureStripe()
    }
    
    private func configureStripe() {
        // Set your publishable key - this should come from environment/config
        guard let publishableKey = getPublishableKey() else {
            print("❌ Stripe publishable key not found")
            return
        }
        
        STPAPIClient.shared.publishableKey = publishableKey
        print("✅ Stripe SDK Configured for Test Environment")
    }
    
    private func getPublishableKey() -> String? {
        // In production, get this from your app's configuration/environment
        // For testing, you can use a test publishable key
        return "pk_test_YOUR_STRIPE_PUBLISHABLE_KEY"
    }
    
    // MARK: - Payment Processing
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
            // Simulate payment processing for test environment
            // In production, this would integrate with actual Stripe PaymentSheet
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            let result = StripePaymentResult(
                paymentIntentId: "pi_test_\(UUID().uuidString.prefix(16))",
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
    
    // MARK: - Test Methods
    func simulatePaymentFailure() async -> Result<StripePaymentResult, StripePaymentError> {
        await MainActor.run {
            isProcessing = true
        }
        
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        await MainActor.run {
            isProcessing = false
        }
        
        return .failure(.paymentFailed(NSError(domain: "StripeTestError", code: 4000, userInfo: [NSLocalizedDescriptionKey: "Test payment failure - card was declined."])))
    }
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
    case paymentCancelled
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
        case .paymentCancelled:
            return "Payment was cancelled"
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
