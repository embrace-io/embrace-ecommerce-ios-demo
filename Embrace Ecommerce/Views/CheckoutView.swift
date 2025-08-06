import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject private var cartManager: CartManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Checkout")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Order Summary")
                        .font(.headline)
                    
                    ForEach(cartManager.cart.items.prefix(3), id: \.id) { item in
                        HStack {
                            Text("Product Item")
                                .font(.subheadline)
                            Spacer()
                            Text("$\(String(format: "%.2f", item.totalPrice))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if cartManager.cart.items.count > 3 {
                        Text("... and \(cartManager.cart.items.count - 3) more items")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                .cornerRadius(10)
                
                Text("This is a demo checkout flow. Full implementation coming soon!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        CheckoutView()
            .environmentObject(CartManager())
    }
}