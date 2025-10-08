import SwiftUI

struct EnhancedShippingMethodView: View {
    let cartItems: [CartItem]
    let shippingAddress: Address
    @Binding var selectedMethod: ShippingMethod?
    
    @StateObject private var shippingService = ShippingCalculationService()
    @State private var showingErrorDetails = false
    @State private var promotionCode = ""
    @State private var appliedPromotions: [String] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            
            if shippingService.isCalculating {
                loadingSection
            } else if let error = shippingService.calculationError {
                errorSection(error)
            } else if !shippingService.availableMethods.isEmpty {
                methodsSection
                promotionSection
                recommendationSection
            } else {
                emptyStateSection
            }
        }
        .onAppear {
            calculateShipping()
        }
        .onChange(of: shippingAddress.zipCode) {
            calculateShipping()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shipping Methods")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Delivering to \(shippingAddress.city), \(shippingAddress.state) \(shippingAddress.zipCode)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var loadingSection: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Calculating shipping rates...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func errorSection(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Shipping Calculation Error")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button {
                calculateShipping(simulateError: false)
            } label: {
                Text("Try Again")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var methodsSection: some View {
        VStack(spacing: 12) {
            ForEach(shippingService.availableMethods, id: \.method.id) { quote in
                ShippingMethodCard(
                    quote: quote,
                    isSelected: selectedMethod?.id == quote.method.id,
                    onSelect: {
                        selectedMethod = quote.method
                        EmbraceService.shared.logInfo(
                            "Shipping method selected",
                            properties: [
                                "method_id": quote.method.id,
                                "method_name": quote.method.name,
                                "cost": String(quote.adjustedCost),
                                "estimated_days": String(quote.method.estimatedDays)
                            ]
                        )
                    }
                )
            }
        }
    }
    
    private var promotionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Promotion Code")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                TextField("Enter promotion code", text: $promotionCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textCase(.uppercase)
                
                Button("Apply") {
                    applyPromotionCode()
                }
                .disabled(promotionCode.isEmpty || appliedPromotions.contains(promotionCode.uppercased()))
            }
            
            if !appliedPromotions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Applied promotions:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(appliedPromotions, id: \.self) { code in
                        HStack {
                            Text(code)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var recommendationSection: some View {
        if let recommended = shippingService.getRecommendedMethod() {
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 Recommended")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text("Based on your cart, we recommend \(recommended.method.name) for the best value")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No shipping methods available")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Please check your shipping address or contact support")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func calculateShipping(simulateError: Bool = false) {
        let request = ShippingCalculationRequest(
            cartItems: cartItems,
            shippingAddress: shippingAddress,
            billingAddress: nil,
            requestedMethods: nil
        )
        
        Task {
            do {
                let _ = try await shippingService.calculateShipping(for: request, simulateError: simulateError)
                if selectedMethod == nil, let firstMethod = shippingService.availableMethods.first {
                    selectedMethod = firstMethod.method
                }
            } catch {
                print("Shipping calculation failed: \(error)")
            }
        }
    }
    
    private func applyPromotionCode() {
        let code = promotionCode.uppercased()
        let updatedQuotes = shippingService.applyShippingPromotion(code: code, to: shippingService.availableMethods)
        
        if updatedQuotes != shippingService.availableMethods {
            shippingService.availableMethods = updatedQuotes
            appliedPromotions.append(code)
            promotionCode = ""

            EmbraceService.shared.logInfo(
                "Shipping promotion applied",
                properties: [
                    "promotion_code": code,
                    "methods_affected": String(updatedQuotes.count)
                ]
            )
        }
    }
}

struct ShippingMethodCard: View {
    let quote: ShippingQuote
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quote.method.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(quote.method.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(quote.method.formattedCost)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(quote.method.cost == 0 ? .green : .primary)
                        
                        if quote.hasPriceAdjustment {
                            Text("$\(String(format: "%.2f", quote.originalCost))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .strikethrough()
                        }
                    }
                }
                
                if let adjustmentReason = quote.adjustmentReason {
                    Text(adjustmentReason)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                
                HStack(spacing: 16) {
                    if quote.method.trackingIncluded {
                        Label("Tracking", systemImage: "location.circle")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    if quote.method.insuranceIncluded {
                        Label("Insurance", systemImage: "shield.checkerboard")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(quote.method.estimatedDeliveryText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !quote.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(quote.warnings, id: \.self) { warning in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                
                                Text(warning)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let sampleProduct = Product(
        id: "1",
        name: "Sample Product",
        description: "A sample product",
        price: 29.99,
        currency: "USD",
        imageUrls: [],
        category: "electronics",
        brand: "Sample Brand",
        variants: [],
        inStock: true,
        stockCount: 10,
        weight: 2.5,
        dimensions: ProductDimensions(width: 12, height: 8, depth: 4)
    )
    
    let sampleCartItem = CartItem(
        id: UUID().uuidString,
        productId: sampleProduct.id,
        quantity: 1,
        selectedVariants: [:],
        addedAt: Date(),
        unitPrice: sampleProduct.price,
        product: sampleProduct
    )
    
    let sampleAddress = Address(
        id: "1",
        firstName: "John",
        lastName: "Doe",
        street: "123 Main St",
        street2: nil,
        city: "San Francisco",
        state: "CA",
        zipCode: "94105",
        country: "US",
        isDefault: true,
        type: .shipping
    )
    
    EnhancedShippingMethodView(
        cartItems: [sampleCartItem],
        shippingAddress: sampleAddress,
        selectedMethod: .constant(nil)
    )
}