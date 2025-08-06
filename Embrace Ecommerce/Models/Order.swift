import Foundation

struct Order: Codable, Identifiable {
    let id: String
    let userId: String?
    let orderNumber: String
    let items: [OrderItem]
    let shippingAddress: Address
    let billingAddress: Address?
    let paymentMethod: PaymentMethod
    let status: OrderStatus
    let subtotal: Double
    let tax: Double
    let shipping: Double
    let total: Double
    let createdAt: Date
    let updatedAt: Date
    let estimatedDelivery: Date?
    let trackingNumber: String?
    
    enum OrderStatus: String, Codable {
        case pending
        case processing
        case shipped
        case delivered
        case cancelled
        case refunded
    }
    
    enum CodingKeys: String, CodingKey {
        case id, items, status, subtotal, tax, shipping, total
        case userId = "user_id"
        case orderNumber = "order_number"
        case shippingAddress = "shipping_address"
        case billingAddress = "billing_address"
        case paymentMethod = "payment_method"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case estimatedDelivery = "estimated_delivery"
        case trackingNumber = "tracking_number"
    }
}

struct OrderItem: Codable, Identifiable {
    let id: String
    let productId: String
    let productName: String
    let quantity: Int
    let unitPrice: Double
    let selectedVariants: [String: String]
    let imageUrl: String?
    
    var totalPrice: Double {
        return unitPrice * Double(quantity)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, quantity
        case productId = "product_id"
        case productName = "product_name"
        case unitPrice = "unit_price"
        case selectedVariants = "selected_variants"
        case imageUrl = "image_url"
    }
}