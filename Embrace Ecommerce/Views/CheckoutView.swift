import SwiftUI
import UIKit

struct CheckoutView: View {
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var coordinator: CheckoutCoordinator?
    @State private var navigateToShipping = false
    @State private var navigateToPayment = false
    @State private var navigateToConfirmation = false

    var body: some View {
        Group {
            if let coordinator = coordinator {
                CartReviewView(coordinator: coordinator)
                    .accessibilityIdentifier("checkoutCartReviewView")
                    .navigationTitle("Checkout")
                    .navigationBarTitleDisplayMode(.inline)
                    .accessibilityIdentifier("checkoutView")
                    .navigationDestination(isPresented: $navigateToShipping) {
                        ShippingInformationViewControllerWrapper(coordinator: coordinator)
                            .navigationTitle("Shipping")
                            .navigationBarTitleDisplayMode(.inline)
                            .accessibilityIdentifier("checkoutShippingStep")
                            .navigationDestination(isPresented: $navigateToPayment) {
                                PaymentSelectionView(coordinator: coordinator)
                                    .navigationTitle("Payment")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .accessibilityIdentifier("checkoutPaymentStep")
                                    .navigationDestination(isPresented: $navigateToConfirmation) {
                                        OrderConfirmationViewControllerWrapper(
                                            coordinator: coordinator,
                                            cartManager: cartManager
                                        )
                                        .navigationBarBackButtonHidden(true)
                                        .accessibilityIdentifier("checkoutConfirmationStep")
                                    }
                            }
                    }
                    .onReceive(coordinator.$currentStep) { step in
                        updateNavigationForStep(step)
                    }
            } else {
                ProgressView("Loading checkout...")
                    .onAppear {
                        initializeCoordinator()
                    }
            }
        }
    }

    private func updateNavigationForStep(_ step: CheckoutCoordinator.CheckoutStep) {
        switch step {
        case .cartReview:
            navigateToShipping = false
            navigateToPayment = false
            navigateToConfirmation = false
        case .shipping:
            navigateToShipping = true
            navigateToPayment = false
            navigateToConfirmation = false
        case .payment:
            navigateToShipping = true
            navigateToPayment = true
            navigateToConfirmation = false
        case .confirmation:
            navigateToShipping = true
            navigateToPayment = true
            navigateToConfirmation = true
        }
    }
    
    private func initializeCoordinator() {
        coordinator = CheckoutCoordinator(cartManager: cartManager)
        setupInitialOrderData()
    }

    private func setupInitialOrderData() {
        guard let coordinator = coordinator else { return }
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
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator

    func makeUIViewController(context: Context) -> UINavigationController {
        let confirmationVC = OrderConfirmationViewController(
            coordinator: coordinator,
            cartManager: cartManager
        )
        confirmationVC.navigationCoordinator = navigationCoordinator
        return UINavigationController(rootViewController: confirmationVC)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Update the navigation coordinator reference if needed
        if let confirmationVC = uiViewController.viewControllers.first as? OrderConfirmationViewController {
            confirmationVC.navigationCoordinator = navigationCoordinator
        }
    }
}

#Preview {
    NavigationView {
        CheckoutView()
            .environmentObject(CartManager())
    }
}