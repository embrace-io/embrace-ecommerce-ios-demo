import Foundation
import Combine
import EmbraceIO

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
        let span = Embrace.client?.buildSpan(
            name: "add_to_cart",
            type: .performance
        ).startSpan()
        
        span?.setAttribute(key: "product.id", value: product.id)
        span?.setAttribute(key: "product.name", value: product.name)
        span?.setAttribute(key: "product.category", value: product.category)
        span?.setAttribute(key: "quantity", value: String(quantity))
        span?.setAttribute(key: "unit_price", value: String(product.price))
        span?.setAttribute(key: "variants_count", value: String(selectedVariants.count))
        
        let existingItemIndex = cart.items.firstIndex { item in
            item.productId == product.id && item.selectedVariants == selectedVariants
        }
        
        if let index = existingItemIndex {
            span?.setAttribute(key: "action", value: "quantity_update")
            span?.setAttribute(key: "previous_quantity", value: String(cart.items[index].quantity))
            updateQuantity(for: cart.items[index].id, quantity: cart.items[index].quantity + quantity)
        } else {
            span?.setAttribute(key: "action", value: "new_item")
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
        
        span?.setAttribute(key: "cart_total_items", value: String(totalItems))
        span?.setAttribute(key: "cart_subtotal", value: String(subtotal))
        span?.end()
        
        // Log successful add to cart
        Embrace.client?.log(
            "Product added to cart successfully",
            severity: .info,
            attributes: [
                "product.id": product.id,
                "product.name": product.name,
                "quantity": String(quantity),
                "cart_total_items": String(totalItems)
            ]
        )
    }
    
    func removeFromCart(itemId: String) {
        let span = Embrace.client?.buildSpan(
            name: "remove_from_cart",
            type: .performance
        ).startSpan()
        
        if let item = cart.items.first(where: { $0.id == itemId }) {
            span?.setAttribute(key: "item.id", value: item.id)
            span?.setAttribute(key: "product.id", value: item.productId)
            span?.setAttribute(key: "quantity", value: String(item.quantity))
            span?.setAttribute(key: "unit_price", value: String(item.unitPrice))
        }
        
        cart.items.removeAll { $0.id == itemId }
        updateCart()
        
        span?.setAttribute(key: "cart_total_items", value: String(totalItems))
        span?.setAttribute(key: "cart_subtotal", value: String(subtotal))
        span?.end()
        
        Embrace.client?.log(
            "Item removed from cart",
            severity: .info,
            attributes: [
                "item.id": itemId,
                "cart_total_items": String(totalItems)
            ]
        )
    }
    
    func updateQuantity(for itemId: String, quantity: Int) {
        let span = Embrace.client?.buildSpan(
            name: "update_cart_quantity",
            type: .performance
        ).startSpan()
        
        if quantity <= 0 {
            span?.setAttribute(key: "action", value: "remove_item")
            span?.end()
            removeFromCart(itemId: itemId)
            return
        }
        
        if let index = cart.items.firstIndex(where: { $0.id == itemId }) {
            let previousQuantity = cart.items[index].quantity
            span?.setAttribute(key: "item.id", value: itemId)
            span?.setAttribute(key: "product.id", value: cart.items[index].productId)
            span?.setAttribute(key: "previous_quantity", value: String(previousQuantity))
            span?.setAttribute(key: "new_quantity", value: String(quantity))
            
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
        
        span?.setAttribute(key: "cart_total_items", value: String(totalItems))
        span?.setAttribute(key: "cart_subtotal", value: String(subtotal))
        span?.end()
    }
    
    func clearCart() {
        let span = Embrace.client?.buildSpan(
            name: "clear_cart",
            type: .performance
        ).startSpan()
        
        let previousItemCount = cart.items.count
        let previousSubtotal = subtotal
        
        span?.setAttribute(key: "previous_item_count", value: String(previousItemCount))
        span?.setAttribute(key: "previous_subtotal", value: String(previousSubtotal))
        
        cart.items.removeAll()
        updateCart()
        
        span?.end()
        
        Embrace.client?.log(
            "Cart cleared",
            severity: .info,
            attributes: [
                "previous_item_count": String(previousItemCount),
                "previous_subtotal": String(previousSubtotal)
            ]
        )
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