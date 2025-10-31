import SwiftUI

enum ViewType: String, CaseIterable {
    case grid = "Grid"
    case list = "List"
    
    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }
}

enum SortOption: String, CaseIterable {
    case featured = "Featured"
    case priceAsc = "Price: Low to High"
    case priceDesc = "Price: High to Low"
    case nameAsc = "Name: A-Z"
    case nameDesc = "Name: Z-A"
    case newest = "Newest"
    
    var systemImage: String {
        switch self {
        case .featured: return "star.fill"
        case .priceAsc: return "arrow.up.circle"
        case .priceDesc: return "arrow.down.circle"
        case .nameAsc: return "textformat.abc"
        case .nameDesc: return "textformat.abc"
        case .newest: return "clock"
        }
    }
}

struct PriceRange {
    var min: Double = 0
    var max: Double = 1000
}

struct ProductListView: View {
    let category: String?
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @StateObject private var apiService = APIService.shared
    
    @State private var products: [Product] = []
    @State private var filteredProducts: [Product] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    // View Controls
    @State private var viewType: ViewType = .grid
    @State private var sortOption: SortOption = .featured
    @State private var showingFilters = false
    @State private var showingSortOptions = false
    @State private var searchText = ""
    
    // Filters
    @State private var selectedBrands: Set<String> = []
    @State private var priceRange = PriceRange()
    @State private var inStockOnly = false
    
    // Pagination
    @State private var currentPage = 1
    @State private var isLoadingMore = false
    @State private var hasMorePages = true
    private let itemsPerPage = 20
    
    var availableBrands: [String] {
        Array(Set(products.compactMap { $0.brand })).sorted()
    }
    
    var body: some View {
        ZStack {
            if isLoading && products.isEmpty {
                loadingView
                    .accessibilityIdentifier("productListLoadingView")
            } else {
                VStack(spacing: 0) {
                    headerSection
                        .accessibilityIdentifier("productListHeaderSection")
                    filtersBar
                        .accessibilityIdentifier("productListFiltersBar")
                    productContent
                        .accessibilityIdentifier("productListContent")
                }
                .accessibilityIdentifier("productListMainContent")
            }

            if showingError {
                errorOverlay
                    .accessibilityIdentifier("productListErrorOverlay")
            }
        }
        .crashTestButton(location: "ProductListView")
        .accessibilityIdentifier("productListView")
        .navigationTitle(category ?? "All Products")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingFilters) {
            FiltersView(
                availableBrands: availableBrands,
                selectedBrands: $selectedBrands,
                priceRange: $priceRange,
                inStockOnly: $inStockOnly,
                onApply: applyFilters,
                onClear: clearFilters
            )
        }
        .refreshable {
            await refreshProducts()
        }
        .onAppear {
            loadInitialProducts()
        }
        .onChange(of: sortOption) { _, _ in
            sortProducts()
        }
        .onChange(of: searchText) { _, newValue in
            filterProducts()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .accessibilityIdentifier("productListLoadingSpinner")

            Text("Loading products...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("productListLoadingText")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Unable to load products")
                .font(.headline)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Retry") {
                showingError = false
                loadInitialProducts()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("productListRetryButton")
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .padding(.horizontal, 32)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            searchBar
                .accessibilityIdentifier("productListSearchBar")
            controlsRow
                .accessibilityIdentifier("productListControlsRow")
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .accessibilityIdentifier("productListSearchIcon")

            TextField("Search in \(category ?? "products")...", text: $searchText)
                .accessibilityIdentifier("productListSearchTextField")

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("productListSearchClearButton")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var controlsRow: some View {
        HStack {
            HStack(spacing: 4) {
                Text("\(filteredProducts.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("productListItemCount")
                Text("items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("productListItemsLabel")
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    showingFilters = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filters")
                    }
                    .font(.subheadline)
                    .foregroundColor(hasActiveFilters ? .blue : .primary)
                }
                .accessibilityIdentifier("productListFiltersButton")
                
                Button(action: {
                    showingSortOptions.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: sortOption.systemImage)
                        Text("Sort")
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                }
                .accessibilityIdentifier("productListSortButton")
                .popover(isPresented: $showingSortOptions, arrowEdge: .top) {
                    sortOptionsMenu
                }
                
                Button(action: {
                    viewType = viewType == .grid ? .list : .grid
                }) {
                    Image(systemName: viewType.icon)
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                .accessibilityIdentifier("productListViewTypeButton")
            }
        }
    }
    
    private var filtersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                if hasActiveFilters {
                    Button("Clear All") {
                        clearFilters()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(16)
                    .accessibilityIdentifier("productListClearAllFiltersButton")
                }
                
                ForEach(Array(selectedBrands), id: \.self) { brand in
                    FilterChip(title: brand) {
                        selectedBrands.remove(brand)
                        applyFilters()
                    }
                    .accessibilityIdentifier("productListBrandFilter_\(brand)")
                }
                
                if inStockOnly {
                    FilterChip(title: "In Stock") {
                        inStockOnly = false
                        applyFilters()
                    }
                    .accessibilityIdentifier("productListInStockFilter")
                }
                
                if priceRange.min > 0 || priceRange.max < 1000 {
                    FilterChip(title: "$\(Int(priceRange.min))-$\(Int(priceRange.max))") {
                        priceRange = PriceRange()
                        applyFilters()
                    }
                    .accessibilityIdentifier("productListPriceRangeFilter")
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, hasActiveFilters ? 8 : 0)
        .frame(height: hasActiveFilters ? 44 : 0)
        .clipped()
    }
    
    private var productContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewType == .grid {
                    gridLayout
                } else {
                    listLayout
                }
                
                if hasMorePages && !filteredProducts.isEmpty {
                    loadMoreButton
                }
                
                Spacer(minLength: 100)
            }
        }
    }
    
    private var gridLayout: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(filteredProducts) { product in
                EnhancedProductCard(product: product, style: .grid) {
                    navigationCoordinator.navigate(to: .productDetail(productId: product.id))
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .accessibilityIdentifier("productListGridLayout")
    }
    
    private var listLayout: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredProducts) { product in
                ProductListRow(product: product) {
                    navigationCoordinator.navigate(to: .productDetail(productId: product.id))
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .accessibilityIdentifier("productListListLayout")
    }
    
    private var loadMoreButton: some View {
        VStack(spacing: 12) {
            if isLoadingMore {
                ProgressView()
                    .scaleEffect(1.2)
            } else {
                Button("Load More Products") {
                    loadMoreProducts()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
                .accessibilityIdentifier("productListLoadMoreButton")
            }
        }
        .padding(.vertical, 16)
    }
    
    private var sortOptionsMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(action: {
                    sortOption = option
                    showingSortOptions = false
                }) {
                    HStack {
                        Image(systemName: option.systemImage)
                            .frame(width: 20)
                        
                        Text(option.rawValue)
                        
                        Spacer()
                        
                        if option == sortOption {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .foregroundColor(.primary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                
                if option != SortOption.allCases.last {
                    Divider()
                }
            }
        }
        .frame(width: 200)
        .background(.regularMaterial)
    }
    
    private var hasActiveFilters: Bool {
        !selectedBrands.isEmpty || inStockOnly || priceRange.min > 0 || priceRange.max < 1000
    }
    
    // MARK: - Data Loading Functions
    
    private func loadInitialProducts() {
        guard !isLoading else { return }
        
        isLoading = true
        currentPage = 1
        hasMorePages = true
        errorMessage = nil
        showingError = false
        
        Task {
            await loadProducts()
        }
    }
    
    private func loadProducts() async {
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
            
            // For now, use mock data directly since the network layer is still in development
            let allProducts = MockDataService.shared.getProducts(for: category)
            
            // Simulate pagination
            let startIndex = (currentPage - 1) * itemsPerPage
            let endIndex = min(startIndex + itemsPerPage, allProducts.count)
            
            let loadedProducts = startIndex < allProducts.count ? 
                Array(allProducts[startIndex..<endIndex]) : []
            
            await MainActor.run {
                if currentPage == 1 {
                    products = loadedProducts
                } else {
                    products.append(contentsOf: loadedProducts)
                }
                
                hasMorePages = endIndex < allProducts.count
                filterAndSortProducts()
                isLoading = false
                isLoadingMore = false
            }
        } catch {
            await handleError(error)
        }
    }
    
    private func loadMoreProducts() {
        guard !isLoadingMore && hasMorePages else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        Task {
            await loadProducts()
        }
    }
    
    @MainActor
    private func refreshProducts() async {
        products = []
        filteredProducts = []
        currentPage = 1
        hasMorePages = true
        await loadProducts()
    }
    
    private func handleError(_ error: Error) async {
        await MainActor.run {
            errorMessage = error.localizedDescription
            if products.isEmpty {
                showingError = true
            }
            isLoading = false
            isLoadingMore = false
        }
    }
    
    // MARK: - Filtering and Sorting
    
    private func filterAndSortProducts() {
        var filtered = products
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.description.localizedCaseInsensitiveContains(searchText) ||
                (product.brand?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply brand filter
        if !selectedBrands.isEmpty {
            filtered = filtered.filter { product in
                guard let brand = product.brand else { return false }
                return selectedBrands.contains(brand)
            }
        }
        
        // Apply price range filter
        filtered = filtered.filter { product in
            product.price >= priceRange.min && product.price <= priceRange.max
        }
        
        // Apply stock filter
        if inStockOnly {
            filtered = filtered.filter { $0.inStock }
        }
        
        // Apply sorting
        filtered = sortProducts(filtered)
        
        filteredProducts = filtered
    }
    
    private func filterProducts() {
        filterAndSortProducts()
    }
    
    private func sortProducts() {
        filteredProducts = sortProducts(filteredProducts)
    }
    
    private func sortProducts(_ products: [Product]) -> [Product] {
        switch sortOption {
        case .featured:
            return products // Keep original order for featured
        case .priceAsc:
            return products.sorted { $0.price < $1.price }
        case .priceDesc:
            return products.sorted { $0.price > $1.price }
        case .nameAsc:
            return products.sorted { $0.name < $1.name }
        case .nameDesc:
            return products.sorted { $0.name > $1.name }
        case .newest:
            return products.reversed() // Assuming newer products are at the end
        }
    }
    
    private func applyFilters() {
        filterAndSortProducts()
    }
    
    private func clearFilters() {
        selectedBrands.removeAll()
        priceRange = PriceRange()
        inStockOnly = false
        applyFilters()
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.blue)
                .accessibilityIdentifier("filterChipTitle")

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .accessibilityIdentifier("filterChipRemoveButton")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .accessibilityIdentifier("filterChip_\(title)")
    }
}

struct ProductListRow: View {
    let product: Product
    let action: () -> Void
    @EnvironmentObject private var cartManager: CartManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: product.imageUrls.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(8)
                .accessibilityIdentifier("productListRowImage_\(product.id)")
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .accessibilityIdentifier("productListRowName_\(product.id)")
                    
                    if let brand = product.brand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("productListRowBrand_\(product.id)")
                    }
                    
                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .accessibilityIdentifier("productListRowDescription_\(product.id)")
                    
                    HStack {
                        Text("$\(String(format: "%.2f", product.price))")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .accessibilityIdentifier("productListRowPrice_\(product.id)")
                        
                        Spacer()
                        
                        if !product.inStock {
                            Text("Out of Stock")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button(action: {
                        cartManager.addToCart(product: product)
                    }) {
                        Image(systemName: "cart.badge.plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .disabled(!product.inStock)
                    .accessibilityIdentifier("productListRowAddToCartButton_\(product.id)")
                    
                    Button(action: {}) {
                        Image(systemName: "heart")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .accessibilityIdentifier("productListRowFavoriteButton_\(product.id)")
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .accessibilityIdentifier("productListRow_\(product.id)")
    }
}

#Preview {
    NavigationView {
        ProductListView(category: "Electronics")
            .environmentObject(NavigationCoordinator())
            .environmentObject(CartManager())
    }
}