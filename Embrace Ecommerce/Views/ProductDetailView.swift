import SwiftUI
import UIKit

struct ProductDetailView: UIViewControllerRepresentable {
    let productId: String
    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let productDetailVC = ProductDetailViewController()
        
        // Load product data
        productDetailVC.product = MockDataService.shared.getProduct(by: productId)
        
        // Set up callbacks
        productDetailVC.onAddToCart = { [weak cartManager] product, quantity, variants in
            cartManager?.addToCart(product: product, quantity: quantity, selectedVariants: variants)
        }
        
        productDetailVC.onClose = {
            context.coordinator.dismiss()
        }
        
        let navController = UINavigationController(rootViewController: productDetailVC)
        navController.navigationBar.prefersLargeTitles = false
        
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Update the view controller if needed
        if let productDetailVC = uiViewController.viewControllers.first as? ProductDetailViewController {
            if productDetailVC.product?.id != productId {
                productDetailVC.product = MockDataService.shared.getProduct(by: productId)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ProductDetailView
        
        init(_ parent: ProductDetailView) {
            self.parent = parent
        }
        
        func dismiss() {
            parent.dismiss()
        }
    }
}

// MARK: - Alternative SwiftUI Product Detail (for comparison)
struct SwiftUIProductDetailView: View {
    let productId: String
    @EnvironmentObject private var cartManager: CartManager
    @State private var product: Product?
    @State private var selectedQuantity = 1
    @State private var selectedVariants: [String: String] = [:]
    @State private var showingAddedConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let product = product {
                    productImageSection(product)
                        .accessibilityIdentifier("productDetailImageSection")
                    productInfoSection(product)
                        .accessibilityIdentifier("productDetailInfoSection")
                    variantsSection(product)
                        .accessibilityIdentifier("productDetailVariantsSection")
                    quantityAndCartSection(product)
                        .accessibilityIdentifier("productDetailQuantityAndCartSection")
                } else {
                    ProgressView("Loading product...")
                        .accessibilityIdentifier("productDetailLoadingView")
                }
            }
            .padding()
        }
        .accessibilityIdentifier("productDetailView")
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadProduct()
        }
        .overlay(
            addedToCartOverlay,
            alignment: .center
        )
    }
    
    private func productImageSection(_ product: Product) -> some View {
        VStack {
            if let firstImageUrl = product.imageUrls.first,
               let url = URL(string: firstImageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .overlay(
                            Image(systemName: "photo.artframe")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                }
            } else {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .overlay(
                        Image(systemName: "photo.artframe")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    )
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func productInfoSection(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(product.name)
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityIdentifier("productDetailName")
            
            if let brand = product.brand {
                Text(brand)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("$\(String(format: "%.2f", product.price))")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .accessibilityIdentifier("productDetailPrice")
            
            stockStatusView(product)
            
            Text(product.description)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func stockStatusView(_ product: Product) -> some View {
        HStack {
            if product.inStock {
                if let stockCount = product.stockCount, stockCount < 10 {
                    Label("Only \(stockCount) left", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Label("In Stock", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            } else {
                Label("Out of Stock", systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
    }
    
    private func variantsSection(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if !product.variants.isEmpty {
                let groupedVariants = Dictionary(grouping: product.variants, by: { $0.type })
                
                ForEach(Array(groupedVariants.keys), id: \.self) { variantType in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(variantType.rawValue.capitalized)
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(groupedVariants[variantType] ?? []) { variant in
                                    variantButton(for: variant, type: variantType)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
            }
        }
    }
    
    private func variantButton(for variant: ProductVariant, type: ProductVariant.VariantType) -> some View {
        let isSelected = selectedVariants[type.rawValue] == variant.value
        
        return Button(action: {
            selectedVariants[type.rawValue] = variant.value
        }) {
            Text(variant.value)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
    
    private func quantityAndCartSection(_ product: Product) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quantity")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        if selectedQuantity > 1 {
                            selectedQuantity -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor(selectedQuantity > 1 ? .blue : .gray)
                    }
                    .disabled(selectedQuantity <= 1)
                    
                    Text("\(selectedQuantity)")
                        .font(.headline)
                        .frame(minWidth: 30)
                    
                    Button(action: {
                        if selectedQuantity < 10 {
                            selectedQuantity += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(selectedQuantity < 10 ? .blue : .gray)
                    }
                    .disabled(selectedQuantity >= 10)
                }
            }
            
            Button(action: {
                addToCart(product)
            }) {
                Text("Add to Cart - $\(String(format: "%.2f", product.price * Double(selectedQuantity)))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(product.inStock ? Color.blue : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!product.inStock)
            .accessibilityIdentifier("productDetailAddToCartButton")
        }
    }
    
    private var addedToCartOverlay: some View {
        Group {
            if showingAddedConfirmation {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Added to Cart!")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(24)
                .background(.regularMaterial)
                .cornerRadius(16)
                .scaleEffect(showingAddedConfirmation ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingAddedConfirmation)
            }
        }
    }
    
    private func loadProduct() {
        product = MockDataService.shared.getProduct(by: productId)
    }
    
    private func addToCart(_ product: Product) {
        cartManager.addToCart(product: product, quantity: selectedQuantity, selectedVariants: selectedVariants)
        
        withAnimation {
            showingAddedConfirmation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingAddedConfirmation = false
            }
        }
    }
}

#Preview {
    NavigationView {
        SwiftUIProductDetailView(productId: "prod_001")
            .environmentObject(CartManager())
    }
}