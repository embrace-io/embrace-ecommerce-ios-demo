import Foundation
import SwiftUI
import UIKit
import StoreKit

@MainActor
class CheckoutCoordinator: ObservableObject {
    @Published var currentStep: CheckoutStep = .cartReview
    @Published var selectedShippingAddress: Address?
    @Published var selectedBillingAddress: Address?
    @Published var selectedPaymentMethod: PaymentMethod?
    @Published var selectedShippingMethod: ShippingMethod?
    @Published var orderData: OrderData

    private let cartManager: CartManager
    private let dataService = MockDataService.shared
    private let analytics = MixpanelAnalyticsService.shared
    private let embraceService = EmbraceService.shared
    private let storeKitManager = StoreKitManager.shared
    
    enum CheckoutStep: Int, CaseIterable, Hashable {
        case cartReview = 0
        case shipping = 1
        case payment = 2
        case confirmation = 3
        
        var title: String {
            switch self {
            case .cartReview: return "Review Cart"
            case .shipping: return "Shipping"
            case .payment: return "Payment"
            case .confirmation: return "Confirmation"
            }
        }
        
        var stepNumber: String {
            return "\(rawValue + 1) of \(CheckoutStep.allCases.count)"
        }
    }
    
    init(cartManager: CartManager) {
        self.cartManager = cartManager
        self.orderData = OrderData(cartItems: cartManager.cart.items)
        updateOrderDataFromCart()
        
        // Track checkout started
        analytics.trackCheckoutStarted(
            itemCount: cartManager.totalItems,
            totalValue: cartManager.subtotal
        )

        // Flow 1 Start: CHECKOUT_STARTED breadcrumb
        embraceService.addBreadcrumb(message: "CHECKOUT_STARTED")
    }
    
    func goToNextStep() {
        guard let nextStep = CheckoutStep(rawValue: currentStep.rawValue + 1) else { return }
        
        switch currentStep {
        case .cartReview:
            updateOrderDataFromCart()
        case .shipping:
            updateOrderDataFromShipping()
        case .payment:
            updateOrderDataFromPayment()
        case .confirmation:
            break
        }
        
        currentStep = nextStep

        // Track checkout step completion
        analytics.trackCheckoutStepCompleted(
            step: nextStep.title.lowercased(),
            itemCount: cartManager.totalItems,
            totalValue: orderData.total
        )

        // Add breadcrumbs for flow transitions
        switch nextStep {
        case .payment:
            // Flow 1 End: CHECKOUT_SHIPPING_COMPLETED
            embraceService.addBreadcrumb(message: "CHECKOUT_SHIPPING_COMPLETED")
        case .confirmation:
            // Flow 2 End: CHECKOUT_PAYMENT_COMPLETED
            embraceService.addBreadcrumb(message: "CHECKOUT_PAYMENT_COMPLETED")
        default:
            break
        }
    }
    
    func goToPreviousStep() {
        guard let previousStep = CheckoutStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = previousStep
    }
    
    func canProceedFromCurrentStep() -> Bool {
        switch currentStep {
        case .cartReview:
            return !cartManager.cart.items.isEmpty
        case .shipping:
            return selectedShippingAddress != nil && selectedShippingMethod != nil
        case .payment:
            return selectedPaymentMethod != nil
        case .confirmation:
            return true
        }
    }
    
    private func updateOrderDataFromCart() {
        orderData.items = cartManager.cart.items.compactMap { cartItem in
            guard let product = dataService.getProduct(by: cartItem.productId) else { return nil }
            return OrderItem(
                id: UUID().uuidString,
                productId: cartItem.productId,
                productName: product.name,
                quantity: cartItem.quantity,
                unitPrice: cartItem.unitPrice,
                selectedVariants: cartItem.selectedVariants,
                imageUrl: product.imageUrls.first
            )
        }
        orderData.subtotal = cartManager.subtotal
        calculateTotals()
    }
    
    private func updateOrderDataFromShipping() {
        orderData.shippingAddress = selectedShippingAddress
        orderData.billingAddress = selectedBillingAddress ?? selectedShippingAddress
        orderData.shippingMethod = selectedShippingMethod
        calculateTotals()
    }
    
    private func updateOrderDataFromPayment() {
        orderData.paymentMethod = selectedPaymentMethod
    }
    
    private func calculateTotals() {
        let shippingCost = selectedShippingMethod?.cost ?? 0.0
        let taxRate = 0.08875
        
        orderData.shipping = shippingCost
        orderData.tax = orderData.subtotal * taxRate
        orderData.total = orderData.subtotal + orderData.tax + orderData.shipping
    }
    
    func placeOrder() async -> Result<Order, Error> {
        guard canProceedFromCurrentStep(),
              let shippingAddress = selectedShippingAddress,
              var paymentMethod = selectedPaymentMethod else {
            return .failure(CheckoutError.missingRequiredData)
        }

        do {
            // Process payment based on payment type
            switch paymentMethod.type {
            case .stripe:
                try await processStripePayment()

            case .storeKit:
                // Process StoreKit payment
                let transaction = try await processStoreKitPayment()
                // Update payment method with transaction ID
                paymentMethod = PaymentMethod(
                    id: paymentMethod.id,
                    type: paymentMethod.type,
                    isDefault: paymentMethod.isDefault,
                    cardInfo: paymentMethod.cardInfo,
                    digitalWalletInfo: paymentMethod.digitalWalletInfo,
                    stripePaymentMethodId: paymentMethod.stripePaymentMethodId,
                    storeKitProductId: paymentMethod.storeKitProductId,
                    storeKitTransactionId: transaction != nil ? String(transaction!.id) : nil
                )
                selectedPaymentMethod = paymentMethod

            default:
                // Other payment methods don't require processing yet
                break
            }

            let order = Order(
                id: UUID().uuidString,
                userId: nil,
                orderNumber: generateOrderNumber(),
                items: orderData.items,
                shippingAddress: shippingAddress,
                billingAddress: selectedBillingAddress ?? shippingAddress,
                paymentMethod: paymentMethod,
                status: determineOrderStatus(for: paymentMethod.type),
                subtotal: orderData.subtotal,
                tax: orderData.tax,
                shipping: orderData.shipping,
                total: orderData.total,
                createdAt: Date(),
                updatedAt: Date(),
                estimatedDelivery: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
                trackingNumber: nil
            )

            // Flow 3 End: Order details API call completed
            embraceService.addBreadcrumb(message: "ORDER_DETAILS_API_COMPLETED")

            return .success(order)
        } catch {
            return .failure(error)
        }
    }

    private func determineOrderStatus(for paymentType: PaymentMethod.PaymentType) -> Order.OrderStatus {
        switch paymentType {
        case .stripe, .storeKit:
            return .processing
        default:
            return .pending
        }
    }
    
    private func processStripePayment() async throws {
        // This method would handle any additional Stripe payment processing
        // For now, it's a placeholder since the payment is already processed in StripePaymentView
        // In a real app, you might want to confirm the payment intent here
        return
    }

    private func processStoreKitPayment() async throws -> StoreKit.Transaction? {
        guard let paymentMethod = selectedPaymentMethod,
              paymentMethod.type == .storeKit,
              let productId = paymentMethod.storeKitProductId else {
            throw CheckoutError.missingRequiredData
        }

        embraceService.addBreadcrumb(message: "STOREKIT_PAYMENT_INITIATED")

        // Find the product
        guard let product = storeKitManager.product(for: productId) else {
            embraceService.logError("StoreKit product not found", properties: [
                "storekit.product_id": productId
            ])
            throw CheckoutError.paymentFailed
        }

        // Purchase the product
        do {
            let transaction = try await storeKitManager.purchase(product)

            if let transaction = transaction {
                embraceService.addBreadcrumb(message: "STOREKIT_PAYMENT_SUCCESS")
                embraceService.logInfo("StoreKit payment completed", properties: [
                    "storekit.product_id": productId,
                    "storekit.transaction_id": String(transaction.id),
                    "order.total": String(orderData.total)
                ])
            } else {
                embraceService.addBreadcrumb(message: "STOREKIT_PAYMENT_CANCELLED")
                embraceService.logWarning("StoreKit payment was cancelled or pending", properties: [
                    "storekit.product_id": productId
                ])
                throw CheckoutError.paymentFailed
            }

            return transaction
        } catch {
            embraceService.addBreadcrumb(message: "STOREKIT_PAYMENT_ERROR")
            embraceService.logError("StoreKit payment failed", properties: [
                "storekit.product_id": productId,
                "error.message": error.localizedDescription
            ])
            throw CheckoutError.paymentFailed
        }
    }

    private func generateOrderNumber() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "ORD-\(timestamp)"
    }
}

struct OrderData {
    var items: [OrderItem]
    var shippingAddress: Address?
    var billingAddress: Address?
    var paymentMethod: PaymentMethod?
    var shippingMethod: ShippingMethod?
    var subtotal: Double = 0.0
    var tax: Double = 0.0
    var shipping: Double = 0.0
    var total: Double = 0.0
    
    init(cartItems: [CartItem]) {
        self.items = []
    }
}


enum CheckoutError: Error, LocalizedError {
    case missingRequiredData
    case paymentFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredData:
            return "Missing required checkout information"
        case .paymentFailed:
            return "Payment processing failed"
        case .networkError:
            return "Network error occurred"
        }
    }
}