import Foundation

struct Product: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let currency: String
    let imageUrls: [String]
    let category: String
    let brand: String?
    let variants: [ProductVariant]
    let inStock: Bool
    let stockCount: Int?
    let weight: Double
    let dimensions: ProductDimensions
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, price, currency, category, brand, variants, weight, dimensions
        case imageUrls = "image_urls"
        case inStock = "in_stock"
        case stockCount = "stock_count"
    }
}

struct ProductDimensions: Codable {
    let width: Double
    let height: Double
    let depth: Double
    
    var volume: Double {
        return width * height * depth
    }
    
    var isOversized: Bool {
        return width > 24 || height > 36 || depth > 24
    }
}

struct ProductVariant: Codable, Identifiable, Hashable {
    let id: String
    let type: VariantType
    let value: String
    let priceAdjustment: Double?
    
    enum VariantType: String, Codable, Hashable {
        case size
        case color
        case style
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, value
        case priceAdjustment = "price_adjustment"
    }
}