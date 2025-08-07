import SwiftUI

struct OrderHistoryView: View {
    @StateObject private var profileManager = UserProfileManager()
    @State private var showingOrderDetail: Order?
    @State private var showingCancelAlert = false
    @State private var orderToCancel: Order?
    
    var body: some View {
        NavigationView {
            ZStack {
                if profileManager.orders.isEmpty && !profileManager.isLoading {
                    emptyStateView
                } else {
                    ordersList
                }
                
                if profileManager.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).opacity(0.8))
                }
            }
            .navigationTitle("Order History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $showingOrderDetail) { order in
                OrderDetailView(order: order)
            }
            .alert("Cancel Order", isPresented: $showingCancelAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Cancel Order", role: .destructive) {
                    if let order = orderToCancel {
                        Task {
                            await profileManager.cancelOrder(id: order.id)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to cancel this order? This action cannot be undone.")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Orders Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your order history will appear here once you make your first purchase")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                // Navigate to home/browse
            } label: {
                Text("Start Shopping")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var ordersList: some View {
        List {
            ForEach(profileManager.orders) { order in
                OrderRowView(order: order) {
                    showingOrderDetail = order
                } onCancel: {
                    orderToCancel = order
                    showingCancelAlert = true
                }
            }
        }
        .refreshable {
            await profileManager.loadOrderHistory()
        }
    }
}

struct OrderRowView: View {
    let order: Order
    let onTap: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with order number and status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Order \(order.orderNumber)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(DateFormatter.orderHistory.string(from: order.createdAt))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    orderStatusBadge
                }
                
                // Order items preview
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(order.items.prefix(2)) { item in
                        HStack {
                            AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                            }
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.productName)
                                    .font(.body)
                                    .lineLimit(1)
                                
                                Text("Qty: \(item.quantity)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("$\(item.unitPrice, specifier: "%.2f")")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if order.items.count > 2 {
                        Text("+ \(order.items.count - 2) more items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 48)
                    }
                }
                
                // Order total and actions
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total: $\(order.total, specifier: "%.2f")")
                            .font(.headline)
                        
                        if let trackingNumber = order.trackingNumber {
                            Text("Tracking: \(trackingNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if canCancelOrder {
                        Button("Cancel") {
                            onCancel()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var orderStatusBadge: some View {
        Text(order.status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch order.status {
        case .pending:
            return .orange
        case .processing:
            return .blue
        case .shipped:
            return .purple
        case .delivered:
            return .green
        case .cancelled:
            return .red
        case .refunded:
            return .gray
        }
    }
    
    private var canCancelOrder: Bool {
        order.status == .pending || order.status == .processing
    }
}

struct OrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Order Header
                    orderHeaderSection
                    
                    // Order Items
                    orderItemsSection
                    
                    // Shipping Address
                    shippingAddressSection
                    
                    // Payment Method
                    paymentMethodSection
                    
                    // Order Summary
                    orderSummarySection
                    
                    // Tracking Information
                    if order.trackingNumber != nil || order.estimatedDelivery != nil {
                        trackingSection
                    }
                }
                .padding()
            }
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var orderHeaderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Order \(order.orderNumber)")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Text("Placed on \(DateFormatter.orderHistory.string(from: order.createdAt))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(order.status.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var orderItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items")
                .font(.headline)
            
            ForEach(order.items) { item in
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.productName)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        if !item.selectedVariants.isEmpty {
                            Text(item.selectedVariants.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Qty: \(item.quantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(item.unitPrice, specifier: "%.2f")")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        if item.quantity > 1 {
                            Text("$\(item.totalPrice, specifier: "%.2f") total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var shippingAddressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shipping Address")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(order.shippingAddress.fullName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(order.shippingAddress.formattedAddress)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment Method")
                .font(.headline)
            
            HStack {
                Image(systemName: paymentMethodIcon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let cardInfo = order.paymentMethod.cardInfo {
                        Text(cardInfo.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(cardInfo.holderName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let digitalWallet = order.paymentMethod.digitalWalletInfo {
                        Text(digitalWallet.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var orderSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Summary")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text("$\(order.subtotal, specifier: "%.2f")")
                }
                
                HStack {
                    Text("Tax")
                    Spacer()
                    Text("$\(order.tax, specifier: "%.2f")")
                }
                
                HStack {
                    Text("Shipping")
                    Spacer()
                    Text(order.shipping == 0 ? "Free" : "$\(order.shipping, specifier: "%.2f")")
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text("$\(order.total, specifier: "%.2f")")
                        .fontWeight(.bold)
                }
            }
            .font(.body)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tracking Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                if let trackingNumber = order.trackingNumber {
                    HStack {
                        Text("Tracking Number:")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(trackingNumber)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
                
                if let estimatedDelivery = order.estimatedDelivery {
                    HStack {
                        Text("Estimated Delivery:")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(DateFormatter.orderHistory.string(from: estimatedDelivery))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch order.status {
        case .pending:
            return .orange
        case .processing:
            return .blue
        case .shipped:
            return .purple
        case .delivered:
            return .green
        case .cancelled:
            return .red
        case .refunded:
            return .gray
        }
    }
    
    private var paymentMethodIcon: String {
        switch order.paymentMethod.type {
        case .creditCard, .debitCard:
            return "creditcard"
        case .applePay:
            return "applelogo"
        case .paypal:
            return "globe"
        case .stripe:
            return "creditcard" 
        }
    }
}

extension DateFormatter {
    static let orderHistory: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    OrderHistoryView()
}
