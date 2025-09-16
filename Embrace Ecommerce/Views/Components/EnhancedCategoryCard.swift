import SwiftUI

struct EnhancedCategoryCard: View {
    let category: Category
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                categoryImage
                    .accessibilityIdentifier("categoryImage_\(category.id)")
                categoryInfo
                    .accessibilityIdentifier("categoryInfo_\(category.id)")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding()
            .background(backgroundGradient)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("categoryCard_\(category.id)")
    }
    
    private var categoryImage: some View {
        Group {
            if let imageUrl = category.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    categoryIcon
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                categoryIcon
            }
        }
    }
    
    private var categoryIcon: some View {
        Image(systemName: iconForCategory(category.name))
            .font(.title2)
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            .background(iconBackgroundColor)
            .clipShape(Circle())
    }
    
    private var categoryInfo: some View {
        VStack(spacing: 4) {
            Text(category.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .accessibilityIdentifier("categoryName_\(category.id)")

            Text("\(category.subcategories.count) items")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("categoryItemCount_\(category.id)")
        }
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemGray6).opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var iconBackgroundColor: Color {
        switch category.name.lowercased() {
        case let name where name.contains("electronic"):
            return .blue
        case let name where name.contains("clothing") || name.contains("fashion"):
            return .purple
        case let name where name.contains("home") || name.contains("garden"):
            return .green
        case let name where name.contains("sport"):
            return .orange
        case let name where name.contains("book"):
            return .brown
        case let name where name.contains("beauty"):
            return .pink
        default:
            return .gray
        }
    }
    
    private func iconForCategory(_ categoryName: String) -> String {
        switch categoryName.lowercased() {
        case let name where name.contains("electronic"):
            return "iphone"
        case let name where name.contains("clothing") || name.contains("fashion"):
            return "tshirt"
        case let name where name.contains("home"):
            return "house"
        case let name where name.contains("garden"):
            return "leaf"
        case let name where name.contains("sport"):
            return "sportscourt"
        case let name where name.contains("book"):
            return "book"
        case let name where name.contains("beauty"):
            return "heart.circle"
        default:
            return "tag"
        }
    }
}

struct DealCard: View {
    let product: Product
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
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
                    .frame(width: 120, height: 90)
                    .clipped()
                    .cornerRadius(8)
                    .accessibilityIdentifier("dealProductImage_\(product.id)")

                    dealBadge
                        .accessibilityIdentifier("dealBadge_\(product.id)")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .accessibilityIdentifier("dealProductName_\(product.id)")

                    HStack {
                        Text("$\(String(format: "%.2f", product.price * 0.8))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .accessibilityIdentifier("dealDiscountedPrice_\(product.id)")

                        Text("$\(String(format: "%.2f", product.price))")
                            .font(.caption2)
                            .strikethrough()
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("dealOriginalPrice_\(product.id)")
                    }
                    .accessibilityIdentifier("dealPricing_\(product.id)")
                }
                .accessibilityIdentifier("dealProductInfo_\(product.id)")
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 120)
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .accessibilityIdentifier("dealCard_\(product.id)")
    }
    
    private var dealBadge: some View {
        Text("20% OFF")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red)
            .cornerRadius(4)
            .offset(x: 4, y: 4)
            .accessibilityIdentifier("dealBadgeText_\(product.id)")
    }
}

#Preview {
    let sampleCategory = Category(
        id: "1",
        name: "Electronics",
        description: "Latest gadgets and tech",
        imageUrl: nil,
        subcategories: ["Phones", "Laptops", "Audio"]
    )
    
    return EnhancedCategoryCard(category: sampleCategory) {
        print("Category tapped")
    }
    .padding()
}