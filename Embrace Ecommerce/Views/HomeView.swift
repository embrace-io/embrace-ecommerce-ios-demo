import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @StateObject private var apiService = APIService.shared
    @StateObject private var mockDataService = MockDataService.shared
    
    @State private var featuredProducts: [Product] = []
    @State private var newArrivals: [Product] = []
    @State private var categories: [Category] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            ZStack {
                if isLoading && featuredProducts.isEmpty {
                    loadingView
                } else {
                    mainContent
                }
                
                if showingError {
                    errorOverlay
                }
            }
            .navigationTitle("Embrace Store")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
            .refreshable {
                await refreshData()
            }
            .onAppear {
                loadInitialData()
            }
        }
    }
    
    private var mainContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                searchBarSection
                
                if !featuredProducts.isEmpty {
                    featuredProductsCarousel
                }
                
                if !categories.isEmpty {
                    categoryGridSection
                }
                
                if !newArrivals.isEmpty {
                    newArrivalsSection
                }
                
                dailyDealsSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading amazing products...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Oops! Something went wrong")
                .font(.headline)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Try Again") {
                showingError = false
                loadInitialData()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .padding(.horizontal, 32)
    }
    
    private var searchBarSection: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search products...", text: $searchText)
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            Button(action: {
                navigationCoordinator.switchTab(to: .search)
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.top, 8)
    }
    
    private var featuredProductsCarousel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Featured Products")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("See All") {
                    navigationCoordinator.navigate(to: .productList(category: nil))
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(featuredProducts) { product in
                        EnhancedProductCard(product: product, style: .featured) {
                            navigationCoordinator.navigate(to: .productDetail(productId: product.id))
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var categoryGridSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Shop by Category")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(categories) { category in
                    EnhancedCategoryCard(category: category) {
                        navigationCoordinator.navigate(to: .productList(category: category.name))
                    }
                }
            }
        }
    }
    
    private var newArrivalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("New Arrivals")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("View All") {
                    navigationCoordinator.navigate(to: .productList(category: nil))
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(newArrivals.prefix(4), id: \.id) { product in
                    EnhancedProductCard(product: product, style: .compact) {
                        navigationCoordinator.navigate(to: .productDetail(productId: product.id))
                    }
                }
            }
        }
    }
    
    private var dailyDealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Daily Deals")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text("24h left")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
            
            if featuredProducts.count > 2 {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(featuredProducts.prefix(3)) { product in
                            DealCard(product: product) {
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
    
    private func loadInitialData() {
        isLoading = true
        errorMessage = nil
        showingError = false
        
        Task {
            await loadAllData()
        }
    }
    
    private func loadAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadFeaturedProducts() }
            group.addTask { await self.loadCategories() }
            group.addTask { await self.loadNewArrivals() }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func loadFeaturedProducts() async {
        do {
            let products = try await apiService.fetchProducts(limit: 8)
            await MainActor.run {
                featuredProducts = products
            }
        } catch {
            await handleError(error, context: "loading featured products")
        }
    }
    
    private func loadCategories() async {
        await MainActor.run {
            categories = mockDataService.getCategories()
        }
    }
    
    private func loadNewArrivals() async {
        do {
            let products = try await apiService.fetchProducts(limit: 6)
            await MainActor.run {
                newArrivals = Array(products.shuffled().prefix(6))
            }
        } catch {
            await handleError(error, context: "loading new arrivals")
        }
    }
    
    @MainActor
    private func refreshData() async {
        await loadAllData()
    }
    
    private func handleError(_ error: Error, context: String) async {
        await MainActor.run {
            errorMessage = "Failed \(context): \(error.localizedDescription)"
            if featuredProducts.isEmpty && categories.isEmpty {
                showingError = true
            }
            isLoading = false
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        navigationCoordinator.switchTab(to: .search)
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