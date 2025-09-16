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
                        .accessibilityIdentifier("homeLoadingView")
                } else {
                    mainContent
                        .accessibilityIdentifier("homeMainContent")
                }

                if showingError {
                    errorOverlay
                        .accessibilityIdentifier("homeErrorOverlay")
                }
            }
            .accessibilityIdentifier("homeView")
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
                .accessibilityIdentifier("homeLoadingSpinner")

            Text("Loading amazing products...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("homeLoadingText")
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
            .accessibilityIdentifier("homeErrorRetryButton")
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
                    .accessibilityIdentifier("homeSearchIcon")

                TextField("Search products...", text: $searchText)
                    .onSubmit {
                        performSearch()
                    }
                    .accessibilityIdentifier("homeSearchTextField")

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityIdentifier("homeSearchClearButton")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .accessibilityIdentifier("homeSearchBar")

            Button(action: {
                navigationCoordinator.switchTab(to: .search)
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .accessibilityIdentifier("homeSearchFiltersButton")
        }
        .padding(.top, 8)
        .accessibilityIdentifier("homeSearchSection")
    }
    
    private var featuredProductsCarousel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Featured Products")
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibilityIdentifier("homeFeaturedProductsTitle")

                Spacer()

                Button("See All") {
                    navigationCoordinator.navigate(to: .productList(category: nil))
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .accessibilityIdentifier("homeFeaturedProductsSeeAllButton")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(featuredProducts) { product in
                        EnhancedProductCard(product: product, style: .featured) {
                            navigationCoordinator.navigate(to: .productDetail(productId: product.id))
                        }
                        .accessibilityIdentifier("homeFeaturedProduct_\(product.id)")
                    }
                }
                .padding(.horizontal, 4)
                .accessibilityIdentifier("homeFeaturedProductsList")
            }
        }
        .accessibilityIdentifier("homeFeaturedProductsSection")
    }
    
    private var categoryGridSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Shop by Category")
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibilityIdentifier("homeCategoriesTitle")

                Spacer()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(categories) { category in
                    EnhancedCategoryCard(category: category) {
                        navigationCoordinator.navigate(to: .productList(category: category.name))
                    }
                    .accessibilityIdentifier("homeCategory_\(category.id)")
                }
            }
            .accessibilityIdentifier("homeCategoriesGrid")
        }
        .accessibilityIdentifier("homeCategoriesSection")
    }
    
    private var newArrivalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("New Arrivals")
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibilityIdentifier("homeNewArrivalsTitle")

                Spacer()

                Button("View All") {
                    navigationCoordinator.navigate(to: .productList(category: nil))
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .accessibilityIdentifier("homeNewArrivalsViewAllButton")
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(newArrivals.prefix(4), id: \.id) { product in
                    EnhancedProductCard(product: product, style: .compact) {
                        navigationCoordinator.navigate(to: .productDetail(productId: product.id))
                    }
                    .accessibilityIdentifier("homeNewArrival_\(product.id)")
                }
            }
            .accessibilityIdentifier("homeNewArrivalsGrid")
        }
        .accessibilityIdentifier("homeNewArrivalsSection")
    }
    
    private var dailyDealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Daily Deals")
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibilityIdentifier("homeDailyDealsTitle")

                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .accessibilityIdentifier("homeDailyDealsIcon")

                Spacer()

                Text("24h left")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                    .accessibilityIdentifier("homeDailyDealsTimer")
            }

            if featuredProducts.count > 2 {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(featuredProducts.prefix(3)) { product in
                            DealCard(product: product) {
                                navigationCoordinator.navigate(to: .productDetail(productId: product.id))
                            }
                            .accessibilityIdentifier("homeDailyDeal_\(product.id)")
                        }
                    }
                    .padding(.horizontal, 4)
                    .accessibilityIdentifier("homeDailyDealsList")
                }
            }
        }
        .accessibilityIdentifier("homeDailyDealsSection")
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


#Preview {
    NavigationView {
        HomeView()
            .environmentObject(NavigationCoordinator())
    }
}