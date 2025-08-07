import SwiftUI
import UIKit

struct CheckoutView: View {
    @EnvironmentObject private var cartManager: CartManager
    @StateObject private var coordinator: CheckoutCoordinator
    @State private var navigationPath = NavigationPath()
    
    init() {
        let cartManager = CartManager()
        self._coordinator = StateObject(wrappedValue: CheckoutCoordinator(cartManager: cartManager))
    }
    
    init(cartManager: CartManager) {
        self._coordinator = StateObject(wrappedValue: CheckoutCoordinator(cartManager: cartManager))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            CartReviewView(coordinator: coordinator)
                .navigationTitle("Checkout")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: CheckoutCoordinator.CheckoutStep.self) { step in
                    destinationView(for: step)
                }
                .onReceive(coordinator.$currentStep) { step in
                    updateNavigationPath(for: step)
                }
                .onAppear {
                    setupInitialOrderData()
                }
        }
    }
    
    @ViewBuilder
    private func destinationView(for step: CheckoutCoordinator.CheckoutStep) -> some View {
        switch step {
        case .cartReview:
            CartReviewView(coordinator: coordinator)
        case .shipping:
            ShippingInformationViewControllerWrapper(coordinator: coordinator)
        case .payment:
            if coordinator.selectedPaymentMethod?.type == .stripe {
                StripePaymentView(coordinator: coordinator)
            } else {
                PaymentSelectionView(coordinator: coordinator)
            }
        case .confirmation:
            OrderConfirmationViewControllerWrapper(
                coordinator: coordinator,
                cartManager: cartManager
            )
        }
    }
    
    private func updateNavigationPath(for step: CheckoutCoordinator.CheckoutStep) {
        switch step {
        case .cartReview:
            navigationPath = NavigationPath()
        case .shipping:
            if navigationPath.isEmpty {
                navigationPath.append(step)
            }
        case .payment:
            if navigationPath.count < 2 {
                navigationPath.append(step)
            }
        case .confirmation:
            if navigationPath.count < 3 {
                navigationPath.append(step)
            }
        }
    }
    
    private func setupInitialOrderData() {
        coordinator.orderData.items = cartManager.cart.items.compactMap { cartItem in
            guard let product = MockDataService.shared.getProduct(by: cartItem.productId) else { return nil }
            return OrderItem(
                id: UUID().uuidString,
                productId: cartItem.productId,
                productName: product.name,
                quantity: cartItem.quantity,
                unitPrice: cartItem.unitPrice,
                selectedVariants: cartItem.selectedVariants,
                imageUrl: product.imageUrls.first
            )
        }
        coordinator.orderData.subtotal = cartManager.subtotal
    }
}

struct ShippingInformationViewControllerWrapper: UIViewControllerRepresentable {
    let coordinator: CheckoutCoordinator
    
    func makeUIViewController(context: Context) -> ShippingInformationViewController {
        return ShippingInformationViewController(coordinator: coordinator)
    }
    
    func updateUIViewController(_ uiViewController: ShippingInformationViewController, context: Context) {
        // No updates needed for this implementation
    }
}

struct OrderConfirmationViewControllerWrapper: UIViewControllerRepresentable {
    let coordinator: CheckoutCoordinator
    let cartManager: CartManager
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let confirmationVC = OrderConfirmationViewController(
            coordinator: coordinator,
            cartManager: cartManager
        )
        return UINavigationController(rootViewController: confirmationVC)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No updates needed for this implementation
    }
}

#Preview {
    NavigationView {
        CheckoutView()
            .environmentObject(CartManager())
    }
}