//
//  StoreKitManager.swift
//  Embrace Ecommerce
//
//  Created for StoreKit telemetry demonstration with Embrace SDK
//

import Foundation
import StoreKit
import EmbraceIO

/// Comprehensive StoreKit 2 manager with full Embrace telemetry integration
/// This demonstrates how StoreKit events and transactions appear in Embrace dashboards
@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    private let embrace = EmbraceService.shared
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Published Properties

    @Published private(set) var products: [StoreKit.Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published var lastTransactionID: String?
    @Published var lastPurchaseError: String?

    // Product IDs from Configuration.storekit
    enum ProductID: String, CaseIterable {
        case singleItem = "com.embrace.ecommerce.single_item"
        case smallCart = "com.embrace.ecommerce.small_cart"
        case mediumCart = "com.embrace.ecommerce.medium_cart"
        case largeCart = "com.embrace.ecommerce.large_cart"
        case premiumShipping = "com.embrace.ecommerce.premium_shipping"
        case tip = "com.embrace.ecommerce.tip"

        var displayName: String {
            switch self {
            case .singleItem: return "Single Item"
            case .smallCart: return "Small Cart"
            case .mediumCart: return "Medium Cart"
            case .largeCart: return "Large Cart"
            case .premiumShipping: return "Premium Shipping"
            case .tip: return "Tip"
            }
        }

        var description: String {
            switch self {
            case .singleItem: return "Single item purchase for your order"
            case .smallCart: return "Small cart purchase (2-3 items)"
            case .mediumCart: return "Medium cart purchase (4-6 items)"
            case .largeCart: return "Large cart purchase (7+ items)"
            case .premiumShipping: return "Premium shipping upgrade"
            case .tip: return "Donation or tip for great service"
            }
        }
    }

    // MARK: - Initialization

    private init() {
        updateListenerTask = listenForTransactions()

        embrace.logInfo("StoreKitManager initialized", properties: [
            "storekit.version": "2",
            "storekit.product_count": String(ProductID.allCases.count)
        ])

        embrace.addBreadcrumb(message: "StoreKit manager initialized")
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    /// Fetch available products from StoreKit
    /// Tracked with Embrace span to measure performance
    func loadProducts() async {
        let startTime = Date()
        let span = embrace.startSpan(name: "storekit_load_products")

        embrace.addBreadcrumb(message: "Loading StoreKit products")
        isLoading = true

        do {
            // Fetch products from App Store Connect / StoreKit Configuration
            let productIDs = ProductID.allCases.map { $0.rawValue }
            let storeProducts = try await StoreKit.Product.products(for: productIDs)

            products = storeProducts

            // Track successful load with Embrace
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)

            span?.setAttribute(key: "storekit.products_loaded", value: String(storeProducts.count))
            span?.setAttribute(key: "storekit.duration_ms", value: String(Int(duration * 1000)))
            span?.setAttribute(key: "storekit.status", value: "success")

            // Log each product
            for product in storeProducts {
                span?.setAttribute(key: "storekit.product.\(product.id)", value: product.displayName)
            }

            embrace.logInfo("StoreKit products loaded successfully", properties: [
                "storekit.product_count": String(storeProducts.count),
                "storekit.duration_ms": String(Int(duration * 1000))
            ])

            embrace.addBreadcrumb(message: "Loaded \(storeProducts.count) StoreKit products")

        } catch {
            // Track error with Embrace
            span?.setAttribute(key: "storekit.status", value: "error")
            span?.setAttribute(key: "storekit.error", value: error.localizedDescription)

            embrace.logError("Failed to load StoreKit products", properties: [
                "error.message": error.localizedDescription,
                "error.type": String(describing: type(of: error))
            ])

            lastPurchaseError = error.localizedDescription
        }

        span?.end()
        isLoading = false
    }

    // MARK: - Purchase Flow

    /// Purchase a product with comprehensive Embrace tracking
    /// Demonstrates full purchase flow telemetry
    func purchase(_ product: StoreKit.Product) async throws -> StoreKit.Transaction? {
        let startTime = Date()
        let span = embrace.startSpan(name: "storekit_purchase")

        // Track purchase attempt
        span?.setAttribute(key: "storekit.product_id", value: product.id)
        span?.setAttribute(key: "storekit.product_name", value: product.displayName)
        span?.setAttribute(key: "storekit.price", value: product.displayPrice)
        span?.setAttribute(key: "storekit.price_value", value: String(describing: product.price))

        embrace.addBreadcrumb(message: "StoreKit purchase initiated: \(product.displayName)")

        embrace.logInfo("StoreKit purchase started", properties: [
            "storekit.product_id": product.id,
            "storekit.product_name": product.displayName,
            "storekit.price": product.displayPrice
        ])

        do {
            // Initiate purchase
            let result = try await product.purchase()

            // Track purchase result
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)

            switch result {
            case .success(let verification):
                // Verify and process transaction
                let transaction = try checkVerified(verification)

                // Track successful purchase
                span?.setAttribute(key: "storekit.status", value: "success")
                span?.setAttribute(key: "storekit.transaction_id", value: String(transaction.id))
                span?.setAttribute(key: "storekit.duration_ms", value: String(Int(duration * 1000)))

                embrace.logInfo("StoreKit purchase successful", properties: [
                    "storekit.product_id": product.id,
                    "storekit.transaction_id": String(transaction.id),
                    "storekit.duration_ms": String(Int(duration * 1000))
                ])

                embrace.addBreadcrumb(message: "StoreKit purchase completed: \(product.displayName)")

                // Deliver content and finish transaction
                await updatePurchasedProducts()
                await transaction.finish()

                lastTransactionID = String(transaction.id)
                span?.end()

                return transaction

            case .userCancelled:
                // Track user cancellation
                span?.setAttribute(key: "storekit.status", value: "user_cancelled")
                span?.setAttribute(key: "storekit.duration_ms", value: String(Int(duration * 1000)))

                embrace.logInfo("StoreKit purchase cancelled by user", properties: [
                    "storekit.product_id": product.id,
                    "storekit.duration_ms": String(Int(duration * 1000))
                ])

                embrace.addBreadcrumb(message: "StoreKit purchase cancelled: \(product.displayName)")

                span?.end()
                return nil

            case .pending:
                // Track pending transaction (requires parental approval, etc.)
                span?.setAttribute(key: "storekit.status", value: "pending")

                embrace.logInfo("StoreKit purchase pending", properties: [
                    "storekit.product_id": product.id
                ])

                embrace.addBreadcrumb(message: "StoreKit purchase pending: \(product.displayName)")

                span?.end()
                return nil

            @unknown default:
                // Track unknown result
                span?.setAttribute(key: "storekit.status", value: "unknown")

                embrace.logWarning("StoreKit purchase returned unknown result", properties: [
                    "storekit.product_id": product.id
                ])

                span?.end()
                return nil
            }

        } catch StoreKitError.userCancelled {
            // Handle explicit cancellation
            span?.setAttribute(key: "storekit.status", value: "cancelled")
            span?.setAttribute(key: "storekit.error_type", value: "user_cancelled")

            embrace.logInfo("StoreKit purchase cancelled", properties: [
                "storekit.product_id": product.id
            ])

            span?.end()
            throw StoreKitError.userCancelled

        } catch {
            // Track purchase error
            span?.setAttribute(key: "storekit.status", value: "error")
            span?.setAttribute(key: "storekit.error", value: error.localizedDescription)
            span?.setAttribute(key: "storekit.error_type", value: String(describing: type(of: error)))

            embrace.logError("StoreKit purchase failed", properties: [
                "storekit.product_id": product.id,
                "error.message": error.localizedDescription,
                "error.type": String(describing: type(of: error))
            ])

            embrace.addBreadcrumb(message: "StoreKit purchase error: \(error.localizedDescription)")

            lastPurchaseError = error.localizedDescription
            span?.end()
            throw error
        }
    }

    // MARK: - Transaction Verification

    /// Verify transaction cryptographic signature
    /// Tracks verification with Embrace
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        let span = embrace.startSpan(name: "storekit_verify_transaction")

        switch result {
        case .unverified(let transaction, let error):
            // Transaction signature verification failed
            span?.setAttribute(key: "storekit.verification_status", value: "failed")
            span?.setAttribute(key: "storekit.verification_error", value: String(describing: error))

            embrace.logError("StoreKit transaction verification failed", properties: [
                "error.type": String(describing: error)
            ])

            span?.end()
            throw error

        case .verified(let transaction):
            // Transaction is verified
            span?.setAttribute(key: "storekit.verification_status", value: "verified")

            embrace.logInfo("StoreKit transaction verified", properties: [:])

            span?.end()
            return transaction
        }
    }

    // MARK: - Transaction Monitoring

    /// Listen for transaction updates in real-time
    /// Tracks all transaction state changes with Embrace
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                await self.handleTransactionUpdate(result)
            }
        }
    }

    private func handleTransactionUpdate(_ verificationResult: VerificationResult<Transaction>) async {
        let span = embrace.startSpan(name: "storekit_transaction_update")

        do {
            let transaction = try checkVerified(verificationResult)

            // Track transaction update
            span?.setAttribute(key: "storekit.transaction_id", value: String(transaction.id))
            span?.setAttribute(key: "storekit.product_id", value: transaction.productID)
            span?.setAttribute(key: "storekit.purchase_date", value: ISO8601DateFormatter().string(from: transaction.purchaseDate))

            if let revocationDate = transaction.revocationDate {
                span?.setAttribute(key: "storekit.revocation_date", value: ISO8601DateFormatter().string(from: revocationDate))
            }

            embrace.logInfo("StoreKit transaction updated", properties: [
                "storekit.transaction_id": String(transaction.id),
                "storekit.product_id": transaction.productID
            ])

            embrace.addBreadcrumb(message: "StoreKit transaction update: \(transaction.productID)")

            // Update purchased products and finish transaction
            await updatePurchasedProducts()
            await transaction.finish()

        } catch {
            span?.setAttribute(key: "storekit.status", value: "error")
            span?.setAttribute(key: "storekit.error", value: error.localizedDescription)

            embrace.logError("Failed to handle StoreKit transaction update", properties: [
                "error.message": error.localizedDescription
            ])
        }

        span?.end()
    }

    // MARK: - Purchase Management

    /// Update the set of purchased products
    /// Scans all transactions to determine current entitlements
    private func updatePurchasedProducts() async {
        let span = embrace.startSpan(name: "storekit_update_purchased")

        var purchasedProducts: Set<String> = []

        // Iterate through all user's transactions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedProducts.insert(transaction.productID)
            } catch {
                embrace.logError("Failed to verify transaction in entitlements", properties: [
                    "error.message": error.localizedDescription
                ])
            }
        }

        purchasedProductIDs = purchasedProducts

        span?.setAttribute(key: "storekit.purchased_count", value: String(purchasedProducts.count))

        embrace.logInfo("Updated StoreKit purchased products", properties: [
            "storekit.purchased_count": String(purchasedProducts.count)
        ])

        span?.end()
    }

    // MARK: - Restore Purchases

    /// Restore previously purchased products
    /// Useful after reinstall or on new device
    func restorePurchases() async throws {
        let startTime = Date()
        let span = embrace.startSpan(name: "storekit_restore_purchases")

        embrace.addBreadcrumb(message: "StoreKit restore purchases initiated")

        do {
            try await AppStore.sync()

            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)

            await updatePurchasedProducts()

            span?.setAttribute(key: "storekit.status", value: "success")
            span?.setAttribute(key: "storekit.restored_count", value: String(purchasedProductIDs.count))
            span?.setAttribute(key: "storekit.duration_ms", value: String(Int(duration * 1000)))

            embrace.logInfo("StoreKit purchases restored", properties: [
                "storekit.restored_count": String(purchasedProductIDs.count),
                "storekit.duration_ms": String(Int(duration * 1000))
            ])

            embrace.addBreadcrumb(message: "StoreKit restored \(purchasedProductIDs.count) purchases")

        } catch {
            span?.setAttribute(key: "storekit.status", value: "error")
            span?.setAttribute(key: "storekit.error", value: error.localizedDescription)

            embrace.logError("Failed to restore StoreKit purchases", properties: [
                "error.message": error.localizedDescription
            ])

            throw error
        }

        span?.end()
    }

    // MARK: - Product Helpers

    /// Check if a product has been purchased
    func isPurchased(_ product: StoreKit.Product) -> Bool {
        return purchasedProductIDs.contains(product.id)
    }

    /// Get product by ID
    func product(for productID: String) -> StoreKit.Product? {
        return products.first { $0.id == productID }
    }

    /// Get suggested product based on cart total
    func suggestedProduct(for cartTotal: Double) -> StoreKit.Product? {
        if cartTotal < 15.0 {
            return product(for: ProductID.singleItem.rawValue)
        } else if cartTotal < 35.0 {
            return product(for: ProductID.smallCart.rawValue)
        } else if cartTotal < 60.0 {
            return product(for: ProductID.mediumCart.rawValue)
        } else {
            return product(for: ProductID.largeCart.rawValue)
        }
    }
}
