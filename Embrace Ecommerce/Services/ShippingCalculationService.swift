import Foundation
import EmbraceIO
import OpenTelemetryApi

enum ShippingCalculationError: LocalizedError {
    case invalidAddress
    case unsupportedDestination
    case cartTooHeavy(maxWeight: Double)
    case oversizedItem
    case hazardousItem
    case networkError
    case serviceTemporarilyUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "Shipping address is invalid"
        case .unsupportedDestination:
            return "We don't ship to this location"
        case .cartTooHeavy(let maxWeight):
            return "Cart is too heavy (max \(maxWeight) lbs)"
        case .oversizedItem:
            return "One or more items exceed size limits"
        case .hazardousItem:
            return "Cart contains hazardous materials"
        case .networkError:
            return "Network error occurred during shipping calculation"
        case .serviceTemporarilyUnavailable:
            return "Shipping calculation service is temporarily unavailable"
        }
    }
}

struct ShippingQuote: Equatable {
    let method: ShippingMethod
    let originalCost: Double
    let adjustedCost: Double
    let adjustmentReason: String?
    let warnings: [String]
    
    var hasPriceAdjustment: Bool {
        return originalCost != adjustedCost
    }
    
    var savings: Double {
        return max(0, originalCost - adjustedCost)
    }
}

struct ShippingCalculationRequest {
    let cartItems: [CartItem]
    let shippingAddress: Address
    let billingAddress: Address?
    let requestedMethods: [String]?
    
    var totalWeight: Double {
        return cartItems.reduce(0) { total, item in
            total + (item.product.weight * Double(item.quantity))
        }
    }
    
    var totalValue: Double {
        return cartItems.reduce(0) { total, item in
            total + (item.product.price * Double(item.quantity))
        }
    }
    
    var hasOversizedItems: Bool {
        return cartItems.contains { item in
            item.product.dimensions.height > 36 ||
            item.product.dimensions.width > 24 ||
            item.product.dimensions.depth > 24
        }
    }
}

@MainActor
class ShippingCalculationService: ObservableObject {
    private let mockNetworkService: MockNetworkService
    private let embraceService = EmbraceService.shared

    @Published var isCalculating = false
    @Published var availableMethods: [ShippingQuote] = []
    @Published var calculationError: String?
    
    private let baseMethods = [
        ShippingMethod(id: "standard", name: "Standard Shipping", description: "5-7 business days", cost: 0.0, estimatedDays: 7, isAvailable: true, trackingIncluded: true, insuranceIncluded: false),
        ShippingMethod(id: "express", name: "Express Shipping", description: "2-3 business days", cost: 9.99, estimatedDays: 3, isAvailable: true, trackingIncluded: true, insuranceIncluded: false),
        ShippingMethod(id: "overnight", name: "Overnight Shipping", description: "1 business day", cost: 24.99, estimatedDays: 1, isAvailable: true, trackingIncluded: true, insuranceIncluded: true),
        ShippingMethod(id: "two_day", name: "Two Day Shipping", description: "2 business days", cost: 14.99, estimatedDays: 2, isAvailable: true, trackingIncluded: true, insuranceIncluded: false),
        ShippingMethod(id: "same_day", name: "Same Day Delivery", description: "Same day (orders before 2 PM)", cost: 19.99, estimatedDays: 0, isAvailable: false, trackingIncluded: true, insuranceIncluded: false)
    ]
    
    init(mockNetworkService: MockNetworkService = .shared) {
        self.mockNetworkService = mockNetworkService
    }
    
    func calculateShipping(for request: ShippingCalculationRequest, simulateError: Bool = false) async throws -> [ShippingQuote] {
        isCalculating = true
        calculationError = nil
        defer { isCalculating = false }

        let span = Embrace.client?.buildSpan(name: "shipping_calculation", type: .performance).startSpan()
        span?.setAttribute(key: "cart.item_count", value: String(request.cartItems.count))
        span?.setAttribute(key: "cart.total_weight", value: String(request.totalWeight))
        span?.setAttribute(key: "cart.total_value", value: String(request.totalValue))
        span?.setAttribute(key: "shipping.destination_state", value: request.shippingAddress.state)
        span?.setAttribute(key: "shipping.destination_zip", value: request.shippingAddress.zipCode)
        span?.setAttribute(key: "shipping.destination_city", value: request.shippingAddress.city)

        do {
            let quotes = try await performShippingCalculation(request, simulateError: simulateError)
            availableMethods = quotes

            span?.setAttribute(key: "shipping.available_methods", value: String(quotes.count))
            span?.setAttribute(key: "shipping.cheapest_cost", value: String(quotes.map { $0.adjustedCost }.min() ?? 0))
            span?.setAttribute(key: "shipping.fastest_days", value: String(quotes.map { $0.method.estimatedDays }.min() ?? 0))
            span?.end()

            embraceService.logInfo(
                "Shipping calculation completed",
                properties: [
                    "shipping.methods_count": String(quotes.count),
                    "cart.total_weight": String(request.totalWeight),
                    "cart.total_value": String(request.totalValue),
                    "shipping.destination": "\(request.shippingAddress.city), \(request.shippingAddress.state)"
                ]
            )

            return quotes

        } catch {
            calculationError = error.localizedDescription
            span?.setAttribute(key: "error.type", value: String(describing: type(of: error)))
            span?.setAttribute(key: "error.message", value: error.localizedDescription)
            span?.end(errorCode: .failure)

            embraceService.logError(
                "Shipping calculation failed",
                properties: [
                    "error.type": String(describing: type(of: error)),
                    "error.message": error.localizedDescription,
                    "cart.items": String(request.cartItems.count),
                    "shipping.destination": "\(request.shippingAddress.city), \(request.shippingAddress.state)"
                ]
            )

            throw error
        }
    }
    
    private func performShippingCalculation(_ request: ShippingCalculationRequest, simulateError: Bool) async throws -> [ShippingQuote] {
        try await Task.sleep(nanoseconds: UInt64.random(in: 800_000_000...2_000_000_000))
        
        if simulateError {
            let errors = [
                ShippingCalculationError.networkError,
                ShippingCalculationError.serviceTemporarilyUnavailable,
                ShippingCalculationError.unsupportedDestination
            ]
            throw errors.randomElement()!
        }
        
        try validateShippingRequest(request)
        
        var quotes: [ShippingQuote] = []
        
        for baseMethod in baseMethods {
            let quote = calculateQuoteForMethod(baseMethod, request: request)
            if quote.method.isAvailable {
                quotes.append(quote)
            }
        }
        
        return quotes.sorted { $0.adjustedCost < $1.adjustedCost }
    }
    
    private func validateShippingRequest(_ request: ShippingCalculationRequest) throws {
        if request.totalWeight > 70 {
            throw ShippingCalculationError.cartTooHeavy(maxWeight: 70)
        }
        
        if request.hasOversizedItems {
            throw ShippingCalculationError.oversizedItem
        }
        
        let restrictedStates = ["AK", "HI", "PR"]
        if restrictedStates.contains(request.shippingAddress.state) {
            throw ShippingCalculationError.unsupportedDestination
        }
        
        if request.cartItems.contains(where: { $0.product.category == "hazardous" }) {
            throw ShippingCalculationError.hazardousItem
        }
    }
    
    private func calculateQuoteForMethod(_ method: ShippingMethod, request: ShippingCalculationRequest) -> ShippingQuote {
        var adjustedCost = method.cost
        var warnings: [String] = []
        var adjustmentReason: String?
        var isAvailable = method.isAvailable
        
        if request.totalWeight > 5.0 && method.cost == 0 {
            adjustedCost = 5.99
            adjustmentReason = "Heavy item surcharge"
        }
        
        if request.totalValue > 100 && method.id == "standard" {
            adjustedCost = 0
            adjustmentReason = "Free shipping on orders over $100"
        }
        
        if request.shippingAddress.state == "CA" && method.id == "same_day" {
            isAvailable = true
        }
        
        let distanceMultiplier = calculateDistanceMultiplier(for: request.shippingAddress)
        if distanceMultiplier > 1.0 && method.cost > 0 {
            adjustedCost *= distanceMultiplier
            adjustmentReason = "Remote area delivery"
        }
        
        if method.id == "overnight" && request.totalWeight > 10 {
            warnings.append("Heavy packages may delay overnight delivery")
        }
        
        if method.id == "express" && request.hasOversizedItems {
            isAvailable = false
            warnings.append("Express shipping not available for oversized items")
        }
        
        let adjustedMethod = ShippingMethod(
            id: method.id,
            name: method.name,
            description: method.description,
            cost: adjustedCost,
            estimatedDays: method.estimatedDays,
            isAvailable: isAvailable,
            trackingIncluded: method.trackingIncluded,
            insuranceIncluded: method.insuranceIncluded || request.totalValue > 500
        )
        
        return ShippingQuote(
            method: adjustedMethod,
            originalCost: method.cost,
            adjustedCost: adjustedCost,
            adjustmentReason: adjustmentReason,
            warnings: warnings
        )
    }
    
    private func calculateDistanceMultiplier(for address: Address) -> Double {
        let remoteCities = ["Anchorage", "Honolulu", "Fairbanks", "Juneau"]
        let remoteStates = ["AK", "HI", "MT", "WY", "ND", "SD"]
        
        if remoteCities.contains(address.city) {
            return 2.5
        }
        
        if remoteStates.contains(address.state) {
            return 1.5
        }
        
        if Int(address.zipCode) ?? 0 < 10000 {
            return 1.3
        }
        
        return 1.0
    }
    
    func getRecommendedMethod() -> ShippingQuote? {
        let availableQuotes = availableMethods.filter { $0.method.isAvailable }
        
        let bestValue = availableQuotes.filter { $0.method.estimatedDays <= 5 }.min { $0.adjustedCost < $1.adjustedCost }
        
        return bestValue ?? availableQuotes.first
    }
    
    func applyShippingPromotion(code: String, to quotes: [ShippingQuote]) -> [ShippingQuote] {
        let discountCodes = [
            "FREESHIP": 1.0,
            "SHIP50": 0.5,
            "FASTSHIP": 0.3
        ]
        
        guard let discount = discountCodes[code.uppercased()] else {
            return quotes
        }
        
        return quotes.map { quote in
            let discountAmount = quote.adjustedCost * discount
            let newCost = max(0, quote.adjustedCost - discountAmount)
            
            let adjustedMethod = ShippingMethod(
                id: quote.method.id,
                name: quote.method.name,
                description: quote.method.description,
                cost: newCost,
                estimatedDays: quote.method.estimatedDays,
                isAvailable: quote.method.isAvailable,
                trackingIncluded: quote.method.trackingIncluded,
                insuranceIncluded: quote.method.insuranceIncluded
            )
            
            return ShippingQuote(
                method: adjustedMethod,
                originalCost: quote.originalCost,
                adjustedCost: newCost,
                adjustmentReason: "Promotional discount applied",
                warnings: quote.warnings
            )
        }
    }
}