import Foundation
import Combine

@MainActor
class CartManager: ObservableObject {
    @Published var cart: Cart = Cart(
        id: UUID().uuidString,
        userId: nil,
        items: [],
        createdAt: Date(),
        updatedAt: Date()
    )
    
    private var cancellables = Set<AnyCancellable>()
    
    var totalItems: Int {
        cart.totalItems
    }
    
    var subtotal: Double {
        cart.subtotal
    }
    
    var isEmpty: Bool {
        cart.items.isEmpty
    }
    
    init() {
        loadCart()
    }
    
    func addToCart(product: Product, quantity: Int = 1, selectedVariants: [String: String] = [:]) {
        let existingItemIndex = cart.items.firstIndex { item in
            item.productId == product.id && item.selectedVariants == selectedVariants
        }
        
        if let index = existingItemIndex {
            updateQuantity(for: cart.items[index].id, quantity: cart.items[index].quantity + quantity)
        } else {
            let newItem = CartItem(
                id: UUID().uuidString,
                productId: product.id,
                quantity: quantity,
                selectedVariants: selectedVariants,
                addedAt: Date(),
                unitPrice: product.price
            )
            cart.items.append(newItem)
        }
        
        updateCart()
    }
    
    func removeFromCart(itemId: String) {
        cart.items.removeAll { $0.id == itemId }
        updateCart()
    }
    
    func updateQuantity(for itemId: String, quantity: Int) {
        if quantity <= 0 {
            removeFromCart(itemId: itemId)
            return
        }
        
        if let index = cart.items.firstIndex(where: { $0.id == itemId }) {
            let updatedItem = CartItem(
                id: cart.items[index].id,
                productId: cart.items[index].productId,
                quantity: quantity,
                selectedVariants: cart.items[index].selectedVariants,
                addedAt: cart.items[index].addedAt,
                unitPrice: cart.items[index].unitPrice
            )
            cart.items[index] = updatedItem
        }
        
        updateCart()
    }
    
    func clearCart() {
        cart.items.removeAll()
        updateCart()
    }
    
    private func updateCart() {
        cart = Cart(
            id: cart.id,
            userId: cart.userId,
            items: cart.items,
            createdAt: cart.createdAt,
            updatedAt: Date()
        )
        saveCart()
    }
    
    private func saveCart() {
        if let encoded = try? JSONEncoder().encode(cart) {
            UserDefaults.standard.set(encoded, forKey: "saved_cart")
        }
    }
    
    private func loadCart() {
        if let data = UserDefaults.standard.data(forKey: "saved_cart"),
           let decodedCart = try? JSONDecoder().decode(Cart.self, from: data) {
            cart = decodedCart
        }
    }
}