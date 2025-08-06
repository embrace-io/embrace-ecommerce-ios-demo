import Foundation

class MockDataService {
    static let shared = MockDataService()
    
    private let mockProducts: [Product] = [
        Product(
            id: "1",
            name: "iPhone 15 Pro",
            description: "The latest iPhone with titanium design and powerful A17 Pro chip.",
            price: 999.99,
            currency: "USD",
            imageUrls: ["https://example.com/iphone15pro.jpg"],
            category: "Electronics",
            brand: "Apple",
            variants: [
                ProductVariant(id: "1a", type: .color, value: "Natural Titanium", priceAdjustment: 0),
                ProductVariant(id: "1b", type: .color, value: "Blue Titanium", priceAdjustment: 0),
                ProductVariant(id: "1c", type: .size, value: "128GB", priceAdjustment: 0),
                ProductVariant(id: "1d", type: .size, value: "256GB", priceAdjustment: 100)
            ],
            inStock: true,
            stockCount: 50
        ),
        Product(
            id: "2",
            name: "AirPods Pro (2nd gen)",
            description: "Active Noise Cancellation with up to 2x more noise cancelling power.",
            price: 249.99,
            currency: "USD",
            imageUrls: ["https://example.com/airpods-pro.jpg"],
            category: "Electronics",
            brand: "Apple",
            variants: [],
            inStock: true,
            stockCount: 25
        ),
        Product(
            id: "3",
            name: "Nike Air Force 1",
            description: "The classic basketball shoe that never goes out of style.",
            price: 110.00,
            currency: "USD",
            imageUrls: ["https://example.com/nike-air-force-1.jpg"],
            category: "Clothing",
            brand: "Nike",
            variants: [
                ProductVariant(id: "3a", type: .size, value: "8", priceAdjustment: 0),
                ProductVariant(id: "3b", type: .size, value: "9", priceAdjustment: 0),
                ProductVariant(id: "3c", type: .size, value: "10", priceAdjustment: 0),
                ProductVariant(id: "3d", type: .color, value: "White", priceAdjustment: 0),
                ProductVariant(id: "3e", type: .color, value: "Black", priceAdjustment: 0)
            ],
            inStock: true,
            stockCount: 15
        ),
        Product(
            id: "4",
            name: "MacBook Air M2",
            description: "Supercharged by M2 chip. Incredibly thin and light laptop.",
            price: 1199.99,
            currency: "USD",
            imageUrls: ["https://example.com/macbook-air-m2.jpg"],
            category: "Electronics",
            brand: "Apple",
            variants: [
                ProductVariant(id: "4a", type: .color, value: "Space Gray", priceAdjustment: 0),
                ProductVariant(id: "4b", type: .color, value: "Silver", priceAdjustment: 0),
                ProductVariant(id: "4c", type: .size, value: "256GB", priceAdjustment: 0),
                ProductVariant(id: "4d", type: .size, value: "512GB", priceAdjustment: 200)
            ],
            inStock: true,
            stockCount: 10
        ),
        Product(
            id: "5",
            name: "Levi's 501 Original Jeans",
            description: "The original blue jean since 1873. A vintage-inspired fit.",
            price: 89.99,
            currency: "USD",
            imageUrls: ["https://example.com/levis-501.jpg"],
            category: "Clothing",
            brand: "Levi's",
            variants: [
                ProductVariant(id: "5a", type: .size, value: "30", priceAdjustment: 0),
                ProductVariant(id: "5b", type: .size, value: "32", priceAdjustment: 0),
                ProductVariant(id: "5c", type: .size, value: "34", priceAdjustment: 0),
                ProductVariant(id: "5d", type: .color, value: "Dark Blue", priceAdjustment: 0),
                ProductVariant(id: "5e", type: .color, value: "Light Blue", priceAdjustment: 0)
            ],
            inStock: true,
            stockCount: 30
        ),
        Product(
            id: "6",
            name: "Coffee Maker Pro",
            description: "Programmable coffee maker with thermal carafe.",
            price: 79.99,
            currency: "USD",
            imageUrls: ["https://example.com/coffee-maker.jpg"],
            category: "Home & Garden",
            brand: "KitchenAid",
            variants: [],
            inStock: true,
            stockCount: 20
        )
    ]
    
    private init() {}
    
    func getFeaturedProducts() -> [Product] {
        Array(mockProducts.prefix(4))
    }
    
    func getProducts(for category: String?) -> [Product] {
        if let category = category {
            return mockProducts.filter { $0.category.lowercased() == category.lowercased() }
        }
        return mockProducts
    }
    
    func getProduct(by id: String) -> Product? {
        mockProducts.first { $0.id == id }
    }
    
    func searchProducts(query: String) -> [Product] {
        let lowercasedQuery = query.lowercased()
        return mockProducts.filter { product in
            product.name.lowercased().contains(lowercasedQuery) ||
            product.description.lowercased().contains(lowercasedQuery) ||
            product.category.lowercased().contains(lowercasedQuery) ||
            (product.brand?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
    
    func getCategories() -> [String] {
        Array(Set(mockProducts.map { $0.category })).sorted()
    }
}