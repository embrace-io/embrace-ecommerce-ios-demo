import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var featuredProducts: [Product] = []
    @State private var categories: [String] = ["Electronics", "Clothing", "Home & Garden", "Sports"]
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    categoriesSection
                    featuredProductsSection
                }
                .padding(.horizontal)
            }
            .navigationTitle("Home")
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
            .onAppear {
                loadFeaturedProducts()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to Embrace Store")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Discover amazing products")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top)
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shop by Category")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryCard(category: category) {
                        navigationCoordinator.navigate(to: .productList(category: category))
                    }
                }
            }
        }
    }
    
    private var featuredProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Products")
                .font(.headline)
                .fontWeight(.semibold)
            
            if featuredProducts.isEmpty {
                ProgressView("Loading products...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(featuredProducts) { product in
                            ProductCard(product: product) {
                                navigationCoordinator.navigate(to: .productDetail(productId: product.id))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .productDetail(let productId):
            ProductDetailView(productId: productId)
        case .productList(let category):
            ProductListView(category: category)
        default:
            Text("Coming Soon")
                .navigationTitle("Coming Soon")
        }
    }
    
    private func loadFeaturedProducts() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            featuredProducts = MockDataService.shared.getFeaturedProducts()
        }
    }
}

struct CategoryCard: View {
    let category: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: iconForCategory(category))
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "electronics":
            return "iphone"
        case "clothing":
            return "tshirt"
        case "home & garden":
            return "house"
        case "sports":
            return "sportscourt"
        default:
            return "tag"
        }
    }
}

struct ProductCard: View {
    let product: Product
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: product.imageUrls.first ?? "")) { image in
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
                .frame(width: 150, height: 120)
                .clipped()
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 150)
    }
}

#Preview {
    NavigationView {
        HomeView()
            .environmentObject(NavigationCoordinator())
    }
}