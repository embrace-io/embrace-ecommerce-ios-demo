import SwiftUI

struct ProductDetailView: View {
    let productId: String
    @State private var product: Product?
    
    var body: some View {
        ScrollView {
            if let product = product {
                VStack(alignment: .leading, spacing: 16) {
                    Text(product.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(product.description)
                        .font(.body)
                    
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding()
            } else {
                ProgressView("Loading product...")
            }
        }
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadProduct()
        }
    }
    
    private func loadProduct() {
        product = MockDataService.shared.getProduct(by: productId)
    }
}

#Preview {
    NavigationView {
        ProductDetailView(productId: "1")
    }
}