import SwiftUI

struct ProductListView: View {
    let category: String?
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var products: [Product] = []
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(products) { product in
                    ProductCard(product: product) {
                        navigationCoordinator.navigate(to: .productDetail(productId: product.id))
                    }
                }
            }
            .padding()
        }
        .navigationTitle(category ?? "All Products")
        .onAppear {
            loadProducts()
        }
    }
    
    private func loadProducts() {
        products = MockDataService.shared.getProducts(for: category)
    }
}

#Preview {
    NavigationView {
        ProductListView(category: "Electronics")
            .environmentObject(NavigationCoordinator())
    }
}