import SwiftUI
import EmbraceIO

struct CartView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var cartManager: CartManager
    @State private var showingClearCartAlert = false
    @State private var isLoading = false
    @State private var showingSavedForLaterSection = false
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else if cartManager.isEmpty {
                    emptyCartView
                } else {
                    cartContentView
                }
            }
            .navigationTitle("Cart")
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
            .toolbar {
                if !cartManager.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            showingClearCartAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Clear Cart", isPresented: $showingClearCartAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    trackClearCartAction()
                    cartManager.clearCart()
                }
            } message: {
                Text("Are you sure you want to remove all items from your cart?")
            }
            .onAppear {
                trackCartView()
            }
        }
    }
    
    private var emptyCartView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Your cart is empty")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add some products to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button("Start Shopping") {
                trackEmptyCartAction()
                navigationCoordinator.switchTab(to: .home)
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
    }
    
    private var cartContentView: some View {
        VStack(spacing: 0) {
            cartItemsList
            
            if showingSavedForLaterSection {
                savedForLaterSection
            }
            
            Divider()
            
            cartSummary
            
            checkoutButton
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading cart...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    private var savedForLaterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved for Later")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Show All") {
                    // Placeholder for saved items functionality
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            Text("No saved items")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
    }
    
    private var cartItemsList: some View {
        List {
            ForEach(cartManager.cart.items) { item in
                CartItemRow(
                    item: item,
                    onQuantityChange: { newQuantity in
                        cartManager.updateQuantity(for: item.id, quantity: newQuantity)
                    },
                    onRemove: {
                        cartManager.removeFromCart(itemId: item.id)
                    }
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    cartManager.removeFromCart(itemId: cartManager.cart.items[index].id)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var cartSummary: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Subtotal (\(cartManager.totalItems) items)")
                    .font(.subheadline)
                
                Spacer()
                
                Text("$\(String(format: "%.2f", cartManager.subtotal))")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("Shipping")
                    .font(.subheadline)
                
                Spacer()
                
                Text("FREE")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("$\(String(format: "%.2f", cartManager.subtotal))")
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var checkoutButton: some View {
        Button("Proceed to Checkout") {
            trackCheckoutAction()
            navigationCoordinator.navigate(to: .checkout)
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .cornerRadius(10)
        .padding()
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .checkout:
            CheckoutView()
        case .productDetail(let productId):
            ProductDetailView(productId: productId)
        default:
            Text("Coming Soon")
                .navigationTitle("Coming Soon")
        }
    }
    
    // MARK: - Telemetry Methods
    private func trackCartView() {
        let span = Embrace.client?.buildSpan(
            name: "view_cart",
            type: .performance
        ).startSpan()
        
        span?.setAttribute(key: "cart_item_count", value: String(cartManager.totalItems))
        span?.setAttribute(key: "cart_subtotal", value: String(cartManager.subtotal))
        span?.setAttribute(key: "is_empty", value: String(cartManager.isEmpty))
        
        span?.end()
        
        Embrace.client?.log(
            "Cart view opened",
            severity: .info,
            attributes: [
                "cart_item_count": String(cartManager.totalItems),
                "cart_subtotal": String(cartManager.subtotal),
                "is_empty": String(cartManager.isEmpty)
            ]
        )
    }
    
    private func trackEmptyCartAction() {
        Embrace.client?.log(
            "Empty cart - start shopping clicked",
            severity: .info
        )
    }
    
    private func trackCheckoutAction() {
        let span = Embrace.client?.buildSpan(
            name: "initiate_checkout",
            type: .performance
        ).startSpan()
        
        span?.setAttribute(key: "cart_item_count", value: String(cartManager.totalItems))
        span?.setAttribute(key: "cart_subtotal", value: String(cartManager.subtotal))
        span?.setAttribute(key: "unique_products", value: String(cartManager.cart.items.count))
        
        span?.end()
        
        Embrace.client?.log(
            "Checkout initiated from cart",
            severity: .info,
            attributes: [
                "cart_item_count": String(cartManager.totalItems),
                "cart_subtotal": String(cartManager.subtotal)
            ]
        )
    }
    
    private func trackClearCartAction() {
        Embrace.client?.log(
            "Clear cart action initiated",
            severity: .info,
            attributes: [
                "items_to_clear": String(cartManager.totalItems),
                "subtotal_to_clear": String(cartManager.subtotal)
            ]
        )
    }
}

struct CartItemRow: View {
    let item: CartItem
    let onQuantityChange: (Int) -> Void
    let onRemove: () -> Void
    
    @State private var product: Product?
    @State private var showingRemoveAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: product?.imageUrls.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 80, height: 80)
            .clipped()
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product?.name ?? "Loading...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if !item.selectedVariants.isEmpty {
                    Text(variantsText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("$\(String(format: "%.2f", item.unitPrice))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    if item.quantity > 1 {
                        Text("x\(item.quantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("Total: $\(String(format: "%.2f", item.totalPrice))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 12) {
                QuantitySelector(
                    quantity: item.quantity,
                    onQuantityChange: { newQuantity in
                        trackQuantityChange(from: item.quantity, to: newQuantity)
                        onQuantityChange(newQuantity)
                    }
                )
                
                Button(action: {
                    showingRemoveAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            loadProduct()
        }
        .alert("Remove Item", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                trackItemRemoval()
                onRemove()
            }
        } message: {
            Text("Are you sure you want to remove this item from your cart?")
        }
    }
    
    private var variantsText: String {
        item.selectedVariants.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }
    
    private func loadProduct() {
        product = MockDataService.shared.getProduct(by: item.productId)
    }
    
    private func trackQuantityChange(from oldQuantity: Int, to newQuantity: Int) {
        Embrace.client?.log(
            "Cart item quantity changed",
            severity: .info,
            attributes: [
                "item.id": item.id,
                "product.id": item.productId,
                "old_quantity": String(oldQuantity),
                "new_quantity": String(newQuantity)
            ]
        )
    }
    
    private func trackItemRemoval() {
        Embrace.client?.log(
            "Cart item removal initiated",
            severity: .info,
            attributes: [
                "item.id": item.id,
                "product.id": item.productId,
                "quantity": String(item.quantity),
                "unit_price": String(item.unitPrice)
            ]
        )
    }
}

struct QuantitySelector: View {
    let quantity: Int
    let onQuantityChange: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                onQuantityChange(max(1, quantity - 1))
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(quantity > 1 ? .blue : .gray)
            }
            .disabled(quantity <= 1)
            
            Text("\(quantity)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(minWidth: 20)
            
            Button(action: {
                onQuantityChange(min(10, quantity + 1))
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(quantity < 10 ? .blue : .gray)
            }
            .disabled(quantity >= 10)
        }
    }
}

#Preview {
    NavigationView {
        CartView()
            .environmentObject(NavigationCoordinator())
            .environmentObject(CartManager())
    }
}