import SwiftUI

enum ProductCardStyle {
    case featured
    case compact
    case grid
}

struct EnhancedProductCard: View {
    let product: Product
    let style: ProductCardStyle
    let action: () -> Void
    
    @EnvironmentObject private var cartManager: CartManager
    @State private var showingAddedConfirmation = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: cardSpacing) {
                productImage
                productInfo
                if style == .featured {
                    actionButtons
                }
            }
            .frame(width: cardWidth)
            .padding(cardPadding)
            .background(cardBackground)
            .cornerRadius(cardCornerRadius)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            stockBadge,
            alignment: .topTrailing
        )
        .overlay(
            confirmationOverlay,
            alignment: .center
        )
    }
    
    private var productImage: some View {
        AsyncImage(url: URL(string: product.imageUrls.first ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color(.systemGray5))
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.gray)
                        
                        Text(product.name)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding()
                )
        }
        .frame(width: imageWidth, height: imageHeight)
        .clipped()
        .cornerRadius(8)
    }
    
    private var productInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name)
                .font(titleFont)
                .fontWeight(.semibold)
                .lineLimit(titleLineLimit)
                .multilineTextAlignment(.leading)
            
            if let brand = product.brand {
                Text(brand)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("$\(String(format: "%.2f", product.price))")
                    .font(priceFont)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if style != .compact {
                    ratingView
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button(action: {
                addToCart()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "cart.badge.plus")
                    Text("Add")
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "heart")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var stockBadge: some View {
        Group {
            if !product.inStock {
                Text("Out of Stock")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(4)
                    .offset(x: -8, y: 8)
            } else if let stockCount = product.stockCount, stockCount < 5 {
                Text("Only \(stockCount) left")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(4)
                    .offset(x: -8, y: 8)
            }
        }
    }
    
    private var confirmationOverlay: some View {
        Group {
            if showingAddedConfirmation {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("Added to Cart!")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)
                .scaleEffect(showingAddedConfirmation ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingAddedConfirmation)
            }
        }
    }
    
    private var ratingView: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { _ in
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
        }
    }
    
    private func addToCart() {
        cartManager.addToCart(product: product)
        
        withAnimation {
            showingAddedConfirmation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingAddedConfirmation = false
            }
        }
    }
    
    private var cardWidth: CGFloat {
        switch style {
        case .featured: return 180
        case .compact: return 160
        case .grid: return 140
        }
    }
    
    private var imageWidth: CGFloat {
        switch style {
        case .featured: return 180
        case .compact: return 160
        case .grid: return 140
        }
    }
    
    private var imageHeight: CGFloat {
        switch style {
        case .featured: return 140
        case .compact: return 120
        case .grid: return 120
        }
    }
    
    private var cardSpacing: CGFloat {
        style == .featured ? 12 : 8
    }
    
    private var cardPadding: CGFloat {
        style == .featured ? 12 : 8
    }
    
    private var cardCornerRadius: CGFloat {
        12
    }
    
    private var cardBackground: Color {
        Color(.systemBackground)
    }
    
    private var titleFont: Font {
        switch style {
        case .featured: return .subheadline
        case .compact: return .caption
        case .grid: return .caption
        }
    }
    
    private var priceFont: Font {
        switch style {
        case .featured: return .subheadline
        case .compact: return .caption
        case .grid: return .caption
        }
    }
    
    private var titleLineLimit: Int {
        style == .featured ? 2 : 2
    }
}