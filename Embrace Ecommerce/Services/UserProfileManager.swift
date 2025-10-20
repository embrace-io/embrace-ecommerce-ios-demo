import Foundation
import Combine
import EmbraceIO
import OpenTelemetryApi

@MainActor
class UserProfileManager: ObservableObject {
    @Published var addresses: [Address] = []
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var orders: [Order] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let mockDataService = MockDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMockData()
    }
    
    // MARK: - Profile Management
    
    func updateUserProfile(firstName: String, lastName: String, email: String, phoneNumber: String?) async -> Bool {
        let span = Embrace.client?.buildSpan(
            name: "update_user_profile",
            type: .performance
        ).startSpan()
        
        isLoading = true
        errorMessage = nil
        
        span?.setAttribute(key: "profile.email", value: email)
        span?.setAttribute(key: "profile.has_phone", value: String(phoneNumber != nil))
        
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))
            
            // Mock update - in real app, this would make API call
            let success = simulateAPICall(successRate: 0.9)
            
            if success {
                span?.setAttribute(key: "update.success", value: "true")
                span?.end()
                
                Embrace.client?.log(
                    "User profile updated successfully",
                    severity: .info,
                    attributes: [
                        "profile.email": email,
                        "profile.has_phone": String(phoneNumber != nil)
                    ]
                )
                
                isLoading = false
                return true
            } else {
                throw NetworkError.httpError(statusCode: 500, data: nil)
            }
            
        } catch {
            handleError(error, span: span, operation: "update_profile")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Address Management
    
    func loadAddresses() async {
        let span = Embrace.client?.buildSpan(
            name: "load_addresses",
            type: .performance
        ).startSpan()
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_500_000_000))
            
            let mockAddresses = generateMockAddresses()
            addresses = mockAddresses
            
            span?.setAttribute(key: "addresses.count", value: String(mockAddresses.count))
            span?.end()
            
            Embrace.client?.log(
                "Addresses loaded successfully",
                severity: .info,
                attributes: [
                    "addresses.count": String(mockAddresses.count)
                ]
            )
            
        } catch {
            handleError(error, span: span, operation: "load_addresses")
        }
        
        isLoading = false
    }
    
    func addAddress(_ address: Address) async -> Bool {
        let span = Embrace.client?.buildSpan(
            name: "add_address",
            type: .performance
        ).startSpan()
        
        isLoading = true
        errorMessage = nil
        
        span?.setAttribute(key: "address.type", value: address.type.rawValue)
        span?.setAttribute(key: "address.country", value: address.country)
        span?.setAttribute(key: "address.is_default", value: String(address.isDefault))
        
        do {
            try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))
            
            let success = simulateAPICall(successRate: 0.85)
            
            if success {
                addresses.append(address)
                
                span?.setAttribute(key: "add_address.success", value: "true")
                span?.end()
                
                Embrace.client?.log(
                    "Address added successfully",
                    severity: .info,
                    attributes: [
                        "address.type": address.type.rawValue,
                        "address.country": address.country
                    ]
                )
                
                isLoading = false
                return true
            } else {
                throw NetworkError.httpError(statusCode: 500, data: nil)
            }
            
        } catch {
            handleError(error, span: span, operation: "add_address")
            isLoading = false
            return false
        }
    }
    
    func updateAddress(_ address: Address) async -> Bool {
        let span = Embrace.client?.buildSpan(
            name: "update_address",
            type: .performance
        ).startSpan()
        
        isLoading = true
        errorMessage = nil
        
        span?.setAttribute(key: "address.id", value: address.id)
        span?.setAttribute(key: "address.type", value: address.type.rawValue)
        
        do {
            try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))
            
            let success = simulateAPICall(successRate: 0.9)
            
            if success {
                if let index = addresses.firstIndex(where: { $0.id == address.id }) {
                    addresses[index] = address
                }
                
                span?.setAttribute(key: "update_address.success", value: "true")
                span?.end()
                
                Embrace.client?.log(
                    "Address updated successfully",
                    severity: .info,
                    attributes: [
                        "address.id": address.id,
                        "address.type": address.type.rawValue
                    ]
                )
                
                isLoading = false
                return true
            } else {
                throw NetworkError.httpError(statusCode: 500, data: nil)
            }
            
        } catch {
            handleError(error, span: span, operation: "update_address")
            isLoading = false
            return false
        }
    }
    
    func deleteAddress(id: String) async -> Bool {
        let span = Embrace.client?.buildSpan(
            name: "delete_address",
            type: .performance
        ).startSpan()
        
        isLoading = true
        errorMessage = nil
        
        span?.setAttribute(key: "address.id", value: id)
        
        do {
            try await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_500_000_000))
            
            let success = simulateAPICall(successRate: 0.95)
            
            if success {
                addresses.removeAll { $0.id == id }
                
                span?.setAttribute(key: "delete_address.success", value: "true")
                span?.end()
                
                Embrace.client?.log(
                    "Address deleted successfully",
                    severity: .info,
                    attributes: [
                        "address.id": id
                    ]
                )
                
                isLoading = false
                return true
            } else {
                throw NetworkError.httpError(statusCode: 500, data: nil)
            }
            
        } catch {
            handleError(error, span: span, operation: "delete_address")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Payment Methods Management
    
    func loadPaymentMethods() async {
        let span = Embrace.client?.buildSpan(
            name: "load_payment_methods",
            type: .performance
        ).startSpan()
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_500_000_000))
            
            let mockPaymentMethods = generateMockPaymentMethods()
            paymentMethods = mockPaymentMethods
            
            span?.setAttribute(key: "payment_methods.count", value: String(mockPaymentMethods.count))
            span?.end()
            
            Embrace.client?.log(
                "Payment methods loaded successfully",
                severity: .info,
                attributes: [
                    "payment_methods.count": String(mockPaymentMethods.count)
                ]
            )
            
        } catch {
            handleError(error, span: span, operation: "load_payment_methods")
        }
        
        isLoading = false
    }
    
    func deletePaymentMethod(id: String) async -> Bool {
        let span = Embrace.client?.buildSpan(
            name: "delete_payment_method",
            type: .performance
        ).startSpan()
        
        isLoading = true
        errorMessage = nil
        
        span?.setAttribute(key: "payment_method.id", value: id)
        
        do {
            try await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_500_000_000))
            
            let success = simulateAPICall(successRate: 0.9)
            
            if success {
                paymentMethods.removeAll { $0.id == id }
                
                span?.setAttribute(key: "delete_payment_method.success", value: "true")
                span?.end()
                
                Embrace.client?.log(
                    "Payment method deleted successfully",
                    severity: .info,
                    attributes: [
                        "payment_method.id": id
                    ]
                )
                
                isLoading = false
                return true
            } else {
                throw NetworkError.httpError(statusCode: 500, data: nil)
            }
            
        } catch {
            handleError(error, span: span, operation: "delete_payment_method")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Order History Management
    
    func loadOrderHistory() async {
        let span = Embrace.client?.buildSpan(
            name: "load_order_history",
            type: .performance
        ).startSpan()
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_500_000_000))
            
            let success = simulateAPICall(successRate: 0.95)
            
            if success {
                let mockOrders = generateMockOrders()
                orders = mockOrders.sorted { $0.createdAt > $1.createdAt }
                
                span?.setAttribute(key: "orders.count", value: String(mockOrders.count))
                span?.end()
                
                Embrace.client?.log(
                    "Order history loaded successfully",
                    severity: .info,
                    attributes: [
                        "orders.count": String(mockOrders.count)
                    ]
                )
            } else {
                throw NetworkError.httpError(statusCode: 500, data: nil)
            }
            
        } catch {
            handleError(error, span: span, operation: "load_order_history")
        }
        
        isLoading = false
    }
    
    func cancelOrder(id: String) async -> Bool {
        let span = Embrace.client?.buildSpan(
            name: "cancel_order",
            type: .performance
        ).startSpan()
        
        isLoading = true
        errorMessage = nil
        
        span?.setAttribute(key: "order.id", value: id)
        
        do {
            try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))
            
            let success = simulateAPICall(successRate: 0.8)
            
            if success {
                if let index = orders.firstIndex(where: { $0.id == id }) {
                    let updatedOrder = orders[index]
                    // Create new order with updated status using reflection of existing properties
                    let cancelledOrder = Order(
                        id: updatedOrder.id,
                        userId: updatedOrder.userId,
                        orderNumber: updatedOrder.orderNumber,
                        items: updatedOrder.items,
                        shippingAddress: updatedOrder.shippingAddress,
                        billingAddress: updatedOrder.billingAddress,
                        paymentMethod: updatedOrder.paymentMethod,
                        status: .cancelled,
                        subtotal: updatedOrder.subtotal,
                        tax: updatedOrder.tax,
                        shipping: updatedOrder.shipping,
                        total: updatedOrder.total,
                        createdAt: updatedOrder.createdAt,
                        updatedAt: Date(),
                        estimatedDelivery: updatedOrder.estimatedDelivery,
                        trackingNumber: updatedOrder.trackingNumber
                    )
                    orders[index] = cancelledOrder
                }
                
                span?.setAttribute(key: "cancel_order.success", value: "true")
                span?.end()
                
                Embrace.client?.log(
                    "Order cancelled successfully",
                    severity: .info,
                    attributes: [
                        "order.id": id
                    ]
                )
                
                isLoading = false
                return true
            } else {
                throw NetworkError.httpError(statusCode: 500, data: nil)
            }
            
        } catch {
            handleError(error, span: span, operation: "cancel_order")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleError(_ error: Error, span: Span?, operation: String) {
        let errorMessage = error.localizedDescription
        self.errorMessage = errorMessage
        
        span?.setAttribute(key: "error.type", value: String(describing: type(of: error)))
        span?.setAttribute(key: "error.description", value: errorMessage)
        span?.end()
        
        Embrace.client?.log(
            "Profile operation failed",
            severity: .error,
            attributes: [
                "operation": operation,
                "error.type": String(describing: type(of: error)),
                "error.description": errorMessage
            ]
        )
    }
    
    private func simulateAPICall(successRate: Double) -> Bool {
        Double.random(in: 0...1) < successRate
    }
    
    private func loadMockData() {
        Task {
            await loadAddresses()
            await loadPaymentMethods() 
            await loadOrderHistory()
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockAddresses() -> [Address] {
        [
            Address(
                id: UUID().uuidString,
                firstName: "John",
                lastName: "Doe",
                street: "123 Main Street",
                street2: "Apt 4B",
                city: "San Francisco",
                state: "CA",
                zipCode: "94105",
                country: "US",
                isDefault: true,
                type: .both
            ),
            Address(
                id: UUID().uuidString,
                firstName: "John",
                lastName: "Doe",
                street: "456 Work Plaza",
                street2: nil,
                city: "Oakland",
                state: "CA",
                zipCode: "94612",
                country: "US",
                isDefault: false,
                type: .shipping
            )
        ]
    }
    
    private func generateMockPaymentMethods() -> [PaymentMethod] {
        [
            PaymentMethod(
                id: UUID().uuidString,
                type: .creditCard,
                isDefault: true,
                cardInfo: CardInfo(
                    last4: "4242",
                    brand: "visa",
                    expiryMonth: 12,
                    expiryYear: 2027,
                    holderName: "John Doe"
                ),
                digitalWalletInfo: nil,
                stripePaymentMethodId: nil,
                storeKitProductId: nil,
                storeKitTransactionId: nil
            ),
            PaymentMethod(
                id: UUID().uuidString,
                type: .applePay,
                isDefault: false,
                cardInfo: nil,
                digitalWalletInfo: DigitalWalletInfo(
                    email: nil,
                    displayName: "Apple Pay"
                ),
                stripePaymentMethodId: nil,
                storeKitProductId: nil,
                storeKitTransactionId: nil
            )
        ]
    }
    
    private func generateMockOrders() -> [Order] {
        let addresses = generateMockAddresses()
        let paymentMethods = generateMockPaymentMethods()
        
        return [
            Order(
                id: UUID().uuidString,
                userId: "user123",
                orderNumber: "ORD-2024-001",
                items: [
                    OrderItem(
                        id: UUID().uuidString,
                        productId: "prod1",
                        productName: "Wireless Headphones",
                        quantity: 1,
                        unitPrice: 199.99,
                        selectedVariants: ["color": "Black"],
                        imageUrl: "https://example.com/headphones.jpg"
                    )
                ],
                shippingAddress: addresses[0],
                billingAddress: addresses[0],
                paymentMethod: paymentMethods[0],
                status: .delivered,
                subtotal: 199.99,
                tax: 16.00,
                shipping: 0.00,
                total: 215.99,
                createdAt: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
                updatedAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
                estimatedDelivery: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
                trackingNumber: "1Z999AA1234567890"
            ),
            Order(
                id: UUID().uuidString,
                userId: "user123",
                orderNumber: "ORD-2024-002",
                items: [
                    OrderItem(
                        id: UUID().uuidString,
                        productId: "prod2",
                        productName: "Smart Watch",
                        quantity: 1,
                        unitPrice: 299.99,
                        selectedVariants: ["size": "42mm", "color": "Silver"],
                        imageUrl: "https://example.com/watch.jpg"
                    )
                ],
                shippingAddress: addresses[0],
                billingAddress: addresses[0],
                paymentMethod: paymentMethods[0],
                status: .processing,
                subtotal: 299.99,
                tax: 24.00,
                shipping: 5.99,
                total: 329.98,
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                updatedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                estimatedDelivery: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                trackingNumber: nil
            )
        ]
    }
}
