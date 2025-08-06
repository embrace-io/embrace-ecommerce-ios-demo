import SwiftUI

struct CartView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var cartManager: CartManager
    @State private var showingClearCartAlert = false
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            VStack(spacing: 0) {
                if cartManager.isEmpty {
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
                    cartManager.clearCart()
                }
            } message: {
                Text("Are you sure you want to remove all items from your cart?")
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
            
            Divider()
            
            cartSummary
            
            checkoutButton
        }
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
}

struct CartItemRow: View {
    let item: CartItem
    let onQuantityChange: (Int) -> Void
    let onRemove: () -> Void
    
    @State private var product: Product?
    
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
                
                Text("$\(String(format: "%.2f", item.unitPrice))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                QuantitySelector(
                    quantity: item.quantity,
                    onQuantityChange: onQuantityChange
                )
                
                Button(action: onRemove) {
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
    }
    
    private var variantsText: String {
        item.selectedVariants.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }
    
    private func loadProduct() {
        product = MockDataService.shared.getProduct(by: item.productId)
    }
}

struct QuantitySelector: View {
    let quantity: Int
    let onQuantityChange: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                onQuantityChange(max(0, quantity - 1))
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
                onQuantityChange(quantity + 1)
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
            }
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