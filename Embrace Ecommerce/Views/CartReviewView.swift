import SwiftUI

struct CartReviewView: View {
    @ObservedObject var coordinator: CheckoutCoordinator
    @EnvironmentObject private var cartManager: CartManager
    @State private var showEditCart = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader
                
                cartSummarySection
                
                orderSummarySection
                
                Spacer(minLength: 20)
                
                continueButton
            }
            .padding()
        }
        .navigationTitle("Review Order")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditCart) {
            NavigationView {
                CartView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showEditCart = false
                            }
                        }
                    }
            }
        }
    }
    
    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(coordinator.currentStep.stepNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(coordinator.currentStep.title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
    
    private var cartSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Items in Cart")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Edit Cart") {
                    showEditCart = true
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(cartManager.cart.items, id: \.id) { item in
                    CartItemRowView(item: item)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var orderSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Subtotal")
                        .font(.subheadline)
                    Spacer()
                    Text("$\(String(format: "%.2f", cartManager.subtotal))")
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Shipping")
                        .font(.subheadline)
                    Spacer()
                    Text("Calculated at next step")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Tax")
                        .font(.subheadline)
                    Spacer()
                    Text("Calculated at next step")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack {
                    Text("Estimated Total")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("$\(String(format: "%.2f", cartManager.subtotal))+")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var continueButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                coordinator.goToNextStep()
            }) {
                HStack {
                    Text("Continue to Shipping")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .background(coordinator.canProceedFromCurrentStep() ? Color.accentColor : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!coordinator.canProceedFromCurrentStep())
            
            if !coordinator.canProceedFromCurrentStep() {
                Text("Add items to cart to continue")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CartItemRowView: View {
    let item: CartItem
    @State private var product: Product?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: product?.imageUrls.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product?.name ?? "Loading...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if !item.selectedVariants.isEmpty {
                    Text(formatVariants(item.selectedVariants))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Text("Qty: \(item.quantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", item.unitPrice))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", item.totalPrice))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            product = MockDataService.shared.getProduct(by: item.productId)
        }
    }
    
    private func formatVariants(_ variants: [String: String]) -> String {
        return variants.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }
}

#Preview {
    NavigationView {
        CartReviewView(coordinator: CheckoutCoordinator(cartManager: CartManager()))
            .environmentObject(CartManager())
    }
}