import Foundation

struct CartItem: Codable, Identifiable {
    let id: String
    let productId: String
    let quantity: Int
    let selectedVariants: [String: String]
    let addedAt: Date
    let unitPrice: Double
    
    var totalPrice: Double {
        return unitPrice * Double(quantity)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, quantity
        case productId = "product_id"
        case selectedVariants = "selected_variants"
        case addedAt = "added_at"
        case unitPrice = "unit_price"
    }
}

struct Cart: Codable {
    let id: String
    let userId: String?
    var items: [CartItem]
    let createdAt: Date
    let updatedAt: Date
    
    var totalItems: Int {
        return items.reduce(0) { $0 + $1.quantity }
    }
    
    var subtotal: Double {
        return items.reduce(0.0) { $0 + $1.totalPrice }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, items
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}