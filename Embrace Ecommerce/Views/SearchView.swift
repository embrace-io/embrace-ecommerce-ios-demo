import SwiftUI
import EmbraceIO

struct SearchView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var searchText = ""
    @State private var searchResults: [Product] = []
    @State private var recentSearches: [String] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            VStack(spacing: 0) {
                searchBar
                    .accessibilityIdentifier("searchBar")

                if searchText.isEmpty {
                    recentSearchesView
                        .accessibilityIdentifier("recentSearchesView")
                } else if isSearching {
                    searchingView
                        .accessibilityIdentifier("searchingView")
                } else {
                    searchResultsView
                        .accessibilityIdentifier("searchResultsView")
                }

                Spacer()
            }
            .accessibilityIdentifier("searchView")
            .navigationTitle("Search")
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
            .onAppear {
                loadRecentSearches()
            }
        }
        .embraceTrace("SearchView")
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .accessibilityIdentifier("searchIcon")

            TextField("Search products...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .accessibilityIdentifier("searchTextField")
                .onSubmit {
                    performSearch()
                }
                .onChange(of: searchText) { _, newValue in
                    if newValue.isEmpty {
                        searchResults.removeAll()
                        isSearching = false
                    } else if newValue.count > 2 {
                        debounceSearch()
                    }
                }

            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                    searchResults.removeAll()
                    isSearching = false
                }
                .font(.caption)
                .foregroundColor(.blue)
                .accessibilityIdentifier("searchClearButton")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Searches")
                        .font(.headline)
                        .padding(.horizontal)
                        .accessibilityIdentifier("recentSearchesTitle")

                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(recentSearches, id: \.self) { search in
                            Button(action: {
                                searchText = search
                                performSearch()
                            }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.gray)
                                        .accessibilityIdentifier("recentSearchIcon")

                                    Text(search)
                                        .foregroundColor(.primary)
                                        .accessibilityIdentifier("recentSearchText_\(search)")

                                    Spacer()

                                    Button(action: {
                                        removeFromRecentSearches(search)
                                    }) {
                                        Image(systemName: "xmark")
                                            .foregroundColor(.gray)
                                            .accessibilityIdentifier("recentSearchRemoveButton_\(search)")
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityIdentifier("recentSearchButton_\(search)")
                        }
                    }
                    .accessibilityIdentifier("recentSearchesList")
                }
            }
            
            popularCategoriesView
            Spacer()
        }
        .padding(.top)
    }
    
    private var popularCategoriesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Categories")
                .font(.headline)
                .padding(.horizontal)
                .accessibilityIdentifier("popularCategoriesTitle")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(["Electronics", "Fashion", "Home", "Sports", "Books", "Beauty"], id: \.self) { category in
                    Button(action: {
                        searchText = category
                        performSearch()
                    }) {
                        Text(category)
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBlue).opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    .accessibilityIdentifier("categoryButton_\(category)")
                }
            }
            .padding(.horizontal)
            .accessibilityIdentifier("popularCategoriesGrid")
        }
    }
    
    private var searchingView: some View {
        VStack(spacing: 16) {
            ProgressView("Searching...")
                .accessibilityIdentifier("searchingSpinner")
            Text("Finding the best products for you")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("searchingText")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var searchResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("\(searchResults.count) results for '\(searchText)'")
                        .font(.headline)
                        .accessibilityIdentifier("searchResultsCount")
                    Spacer()
                }
                .padding(.horizontal)
                
                if searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                            .accessibilityIdentifier("noResultsIcon")

                        Text("No results found")
                            .font(.title3)
                            .fontWeight(.medium)
                            .accessibilityIdentifier("noResultsTitle")

                        Text("Try adjusting your search terms")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("noResultsSubtitle")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(searchResults) { product in
                            EnhancedProductCard(product: product, style: .grid) {
                                navigationCoordinator.navigate(to: .productDetail(productId: product.id))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .accessibilityIdentifier("searchResultsList")
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
    
    private func debounceSearch() {
        isSearching = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !searchText.isEmpty {
                performSearch()
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        addToRecentSearches(searchText)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            searchResults = MockDataService.shared.searchProducts(query: searchText)
            isSearching = false
        }
    }
    
    private func addToRecentSearches(_ search: String) {
        var searches = recentSearches.filter { $0 != search }
        searches.insert(search, at: 0)
        recentSearches = Array(searches.prefix(5))
        saveRecentSearches()
    }
    
    private func removeFromRecentSearches(_ search: String) {
        recentSearches.removeAll { $0 == search }
        saveRecentSearches()
    }
    
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: "recent_searches")
    }
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recent_searches") ?? []
    }
}

#Preview {
    NavigationView {
        SearchView()
            .environmentObject(NavigationCoordinator())
    }
}