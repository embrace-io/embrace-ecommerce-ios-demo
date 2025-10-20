import Foundation
import UIKit
import Stripe
import EmbraceIO
import OpenTelemetryApi

@MainActor
class StripePaymentService: ObservableObject {
    static let shared = StripePaymentService()

    // MARK: - Published Properties
    @Published var paymentResult: StripePaymentResult?
    @Published var isProcessing = false

    private let embraceService = EmbraceService.shared

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
        // Get your test key from: https://dashboard.stripe.com/test/apikeys
        return "YOUR_STRIPE_TEST_PUBLISHABLE_KEY"
    }
    
    // MARK: - Payment Processing
    func processPayment(amount: Double, currency: String = "usd") async -> Result<StripePaymentResult, StripePaymentError> {
        let span = Embrace.client?.buildSpan(name: "stripe_payment_processing", type: .performance).startSpan()
        span?.setAttribute(key: "payment.amount", value: String(amount))
        span?.setAttribute(key: "payment.currency", value: currency)
        span?.setAttribute(key: "payment.provider", value: "stripe")

        guard amount > 0 else {
            span?.setAttribute(key: "error.type", value: "invalid_amount")
            span?.setAttribute(key: "error.reason", value: "amount_zero_or_negative")
            span?.end(errorCode: .failure)

            embraceService.logError("Payment processing failed - Invalid amount", properties: [
                "payment.amount": String(amount),
                "payment.currency": currency,
                "error.type": "invalid_amount"
            ])

            return .failure(.invalidAmount)
        }

        guard amount >= 0.50 else {
            span?.setAttribute(key: "error.type", value: "amount_too_small")
            span?.setAttribute(key: "error.minimum_amount", value: "0.50")
            span?.end(errorCode: .failure)

            embraceService.logError("Payment processing failed - Amount too small", properties: [
                "payment.amount": String(amount),
                "payment.currency": currency,
                "payment.minimum_required": "0.50",
                "error.type": "amount_too_small"
            ])

            return .failure(.amountTooSmall)
        }

        await MainActor.run {
            isProcessing = true
        }

        let startTime = Date()

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

            let duration = Date().timeIntervalSince(startTime)
            span?.setAttribute(key: "payment.intent_id", value: result.paymentIntentId)
            span?.setAttribute(key: "payment.status", value: result.status.rawValue)
            span?.setAttribute(key: "payment.method_id", value: result.paymentMethodId)
            span?.setAttribute(key: "payment.duration_ms", value: String(Int(duration * 1000)))
            span?.end()

            embraceService.logInfo("Payment processed successfully", properties: [
                "payment.intent_id": result.paymentIntentId,
                "payment.amount": String(amount),
                "payment.currency": currency,
                "payment.status": result.status.rawValue,
                "payment.duration_ms": String(Int(duration * 1000))
            ])

            await MainActor.run {
                paymentResult = result
                isProcessing = false
            }

            return .success(result)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            span?.setAttribute(key: "error.type", value: "payment_failed")
            span?.setAttribute(key: "error.message", value: error.localizedDescription)
            span?.setAttribute(key: "payment.duration_ms", value: String(Int(duration * 1000)))
            span?.end(errorCode: .failure)

            embraceService.logError("Payment processing failed", properties: [
                "payment.amount": String(amount),
                "payment.currency": currency,
                "error.type": "payment_failed",
                "error.message": error.localizedDescription,
                "payment.duration_ms": String(Int(duration * 1000))
            ])

            await MainActor.run {
                isProcessing = false
            }
            return .failure(.paymentFailed(error))
        }
    }
    
    // MARK: - Test Methods
    func simulatePaymentFailure() async -> Result<StripePaymentResult, StripePaymentError> {
        let span = Embrace.client?.buildSpan(name: "stripe_payment_test_failure", type: .performance).startSpan()
        span?.setAttribute(key: "payment.provider", value: "stripe")
        span?.setAttribute(key: "payment.test_mode", value: "true")
        span?.setAttribute(key: "payment.simulation_type", value: "failure")

        await MainActor.run {
            isProcessing = true
        }

        let startTime = Date()
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        let duration = Date().timeIntervalSince(startTime)
        let error = NSError(domain: "StripeTestError", code: 4000, userInfo: [NSLocalizedDescriptionKey: "Test payment failure - card was declined."])

        span?.setAttribute(key: "error.type", value: "card_declined")
        span?.setAttribute(key: "error.code", value: "4000")
        span?.setAttribute(key: "error.message", value: error.localizedDescription)
        span?.setAttribute(key: "payment.duration_ms", value: String(Int(duration * 1000)))
        span?.end(errorCode: .failure)

        embraceService.logError("Simulated payment failure", properties: [
            "payment.provider": "stripe",
            "payment.test_mode": "true",
            "error.type": "card_declined",
            "error.code": "4000",
            "error.message": error.localizedDescription,
            "payment.duration_ms": String(Int(duration * 1000))
        ])

        await MainActor.run {
            isProcessing = false
        }

        return .failure(.paymentFailed(error))
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
