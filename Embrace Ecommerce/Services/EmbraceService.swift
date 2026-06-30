//
//  EmbraceService.swift
//  Embrace Ecommerce
//
//  Created by Sergio Rodriguez on 8/7/25.
//

import Foundation
import EmbraceIO

// MARK: - Public Surface

/// Abstraction over Embrace so feature code never imports EmbraceIO directly.
/// Swap the implementation for a mock/no-op in tests.
protocol TelemetryService {
    // Logs
    func logInfo(_ message: String, properties: [String: String]?)
    func logWarning(_ message: String, properties: [String: String]?)
    func logError(_ message: String, properties: [String: String]?)
    func logDebug(_ message: String, properties: [String: String]?)

    // Spans
    func startSpan(name: String) -> EmbraceSpan?
    func recordCompletedSpan(
        name: String,
        startTime: Date,
        endTime: Date,
        attributes: [String: String]?,
        errorCode: EmbraceSpanErrorCode?
    )
    func recordSpan<T>(name: String, attributes: [String: String], block: (EmbraceSpan?) throws -> T) rethrows -> T

    // Events
    func addBreadcrumb(message: String)

    // Metadata (session, process, or permanent scope)
    func addSessionProperty(key: String, value: String, permanent: Bool)
    func removeSessionProperty(key: String)

    // User identity
    func setUser(id: String?, email: String?, name: String?)
    func clearUser()

    // Persona tags (segmentation)
    func addPersona(_ tag: String, permanent: Bool)
    func removePersona(_ tag: String, permanent: Bool)

    // Manual network + push
    func recordNetworkRequest(url: String, method: String, startTime: Date, endTime: Date, statusCode: Int?, errorMessage: String?, traceId: String?)
    func recordPushNotification(userInfo: [AnyHashable: Any])
}

final class EmbraceService: TelemetryService {
    static let shared = EmbraceService()

    private init() {}

    // MARK: - Logs

    func logInfo(_ message: String, properties: [String: String]? = nil) {
        EmbraceIO.shared.log(message, severity: .info, attributes: properties ?? [:])
    }

    func logWarning(_ message: String, properties: [String: String]? = nil) {
        EmbraceIO.shared.log(message, severity: .warn, attributes: properties ?? [:])
    }

    func logError(_ message: String, properties: [String: String]? = nil) {
        EmbraceIO.shared.log(message, severity: .error, attributes: properties ?? [:])
    }

    func logDebug(_ message: String, properties: [String: String]? = nil) {
        EmbraceIO.shared.log(message, severity: .debug, attributes: properties ?? [:])
    }

    // MARK: - Spans

    /// Returns a started span. Caller owns calling `.end()` (or `.end(errorCode:)`).
    func startSpan(name: String) -> EmbraceSpan? {
        EmbraceIO.shared.createSpan(name: name, type: .performance)
    }

    /// Records a span that already happened. Honors real start/end times and
    /// optionally marks it as failed so it shows up as an error in the dashboard.
    func recordCompletedSpan(
        name: String,
        startTime: Date,
        endTime: Date,
        attributes: [String: String]? = nil,
        errorCode: EmbraceSpanErrorCode? = nil
    ) {
        // 7.0: createSpan(endTime:) cannot carry an errorCode, so create the span
        // (started) and end it with the code to preserve failure/userAbandon semantics.
        let span = EmbraceIO.shared.createSpan(
            name: name,
            type: .performance,
            startTime: startTime,
            attributes: attributes ?? [:]
        )
        span?.end(errorCode: errorCode, endTime: endTime)
    }

    /// Block-based span. Preferred for short synchronous work — auto-ends,
    /// and the block still runs if Embrace.client is nil (e.g., pre-start).
    @discardableResult
    func recordSpan<T>(
        name: String,
        attributes: [String: String] = [:],
        block: (EmbraceSpan?) throws -> T
    ) rethrows -> T {
        // 7.0 removed the block-based `Embrace.recordSpan` helper with no
        // replacement. Recreate it: start a span, run the block, end the span.
        // `createSpan` returns nil if the SDK isn't started — the block still runs.
        let span = EmbraceIO.shared.createSpan(name: name, type: .performance, attributes: attributes)
        defer { span?.end() }
        return try block(span)
    }

    // MARK: - Breadcrumbs

    func addBreadcrumb(message: String) {
        EmbraceIO.shared.addBreadcrumb(message)
    }

    // MARK: - Session Properties

    func addSessionProperty(key: String, value: String, permanent: Bool = false) {
        EmbraceIO.shared.setProperty(
            key: key,
            value: value,
            lifespan: permanent ? .permanent : .session
        )
    }

    func removeSessionProperty(key: String) {
        EmbraceIO.shared.setProperty(key: key, value: nil, lifespan: .session)
    }

    // MARK: - User Identity

    /// Sets built-in user fields (id/email/name). Persists across sessions
    /// until `clearUser()` is called. Pass `nil` to leave a field unchanged.
    func setUser(id: String?, email: String? = nil, name: String? = nil) {
        if let id = id { EmbraceIO.shared.userIdentifier = id }
        // 7.0 removed metadata.userEmail / userName. Documented workaround:
        // store them as permanent session properties.
        if let email = email {
            EmbraceIO.shared.setProperty(key: "user_email", value: email, lifespan: .permanent)
        }
        if let name = name {
            EmbraceIO.shared.setProperty(key: "user_name", value: name, lifespan: .permanent)
        }
    }

    func clearUser() {
        // 7.0 removed clearUserProperties(); clear the identifier and the
        // email/name properties we set above.
        EmbraceIO.shared.userIdentifier = nil
        EmbraceIO.shared.setProperty(key: "user_email", value: nil, lifespan: .permanent)
        EmbraceIO.shared.setProperty(key: "user_name", value: nil, lifespan: .permanent)
    }

    // MARK: - Personas

    func addPersona(_ tag: String, permanent: Bool = false) {
        EmbraceIO.shared.addPersona(tag, lifespan: permanent ? .permanent : .session)
    }

    func removePersona(_ tag: String, permanent: Bool = false) {
        EmbraceIO.shared.removePersona(tag, lifespan: permanent ? .permanent : .session)
    }

    // MARK: - Network Monitoring
    // The SDK's URLSessionCaptureService auto-captures URLSession traffic.
    // Use this only for custom transports the SDK cannot see (e.g. 3rd-party clients).

    func recordNetworkRequest(
        url: String,
        method: String,
        startTime: Date,
        endTime: Date,
        statusCode: Int?,
        errorMessage: String?,
        traceId: String?
    ) {
        var attributes: [String: String] = [
            "http.url": url,
            "http.method": method
        ]
        if let statusCode = statusCode { attributes["http.status_code"] = String(statusCode) }
        if let traceId = traceId { attributes["http.trace_id"] = traceId }
        if let errorMessage = errorMessage { attributes["error.message"] = errorMessage }

        let span = EmbraceIO.shared.createSpan(
            name: "network_request",
            type: .networkRequest,
            startTime: startTime,
            attributes: attributes
        )
        span?.end(errorCode: errorMessage == nil ? nil : .failure, endTime: endTime)
    }

    // MARK: - Push Notifications

    /// Preferred: pass the raw `userInfo` from
    /// `didReceiveRemoteNotification` / `UNUserNotificationCenterDelegate`.
    /// The SDK parses the `aps` payload (title/body/category/badge) for you.
    func recordPushNotification(userInfo: [AnyHashable: Any]) {
        EmbraceIO.shared.addPushNotificationEvent(userInfo: userInfo, captureData: true)
        addBreadcrumb(message: "Push notification received")
    }

    // MARK: - User Journey

    func trackUserAction(_ action: String, screen: String, properties: [String: String]? = nil) {
        let breadcrumbMessage = "\(action) on \(screen)"
        addBreadcrumb(message: breadcrumbMessage)

        var logProperties = properties ?? [:]
        logProperties["user_action"] = action
        logProperties["screen"] = screen

        logInfo("User action: \(breadcrumbMessage)", properties: logProperties)
    }

    func trackScreenView(_ screenName: String, properties: [String: String]? = nil) {
        addBreadcrumb(message: "Viewed \(screenName)")

        var logProperties = properties ?? [:]
        logProperties["screen_name"] = screenName

        logInfo("Screen view: \(screenName)", properties: logProperties)
    }

    // MARK: - E-commerce Tracking

    func trackProductView(productId: String, productName: String, category: String?, price: Double?) {
        recordSpan(name: "product_view", attributes: [
            "product.id": productId,
            "product.name": productName,
            "product.category": category ?? "",
            "product.price": price.map { String($0) } ?? ""
        ].filter { !$0.value.isEmpty }) { _ in
            trackUserAction("product_view", screen: "product_detail", properties: [
                "product_id": productId,
                "product_name": productName
            ])
        }
    }

    func trackAddToCart(productId: String, quantity: Int, price: Double) {
        recordSpan(name: "add_to_cart", attributes: [
            "product.id": productId,
            "cart.quantity": String(quantity),
            "cart.item_value": String(price)
        ]) { _ in
            trackUserAction("add_to_cart", screen: "product_detail", properties: [
                "product_id": productId,
                "quantity": String(quantity),
                "value": String(price)
            ])
        }
    }

    func trackPurchaseAttempt(orderId: String, totalAmount: Double, itemCount: Int) {
        recordSpan(name: "purchase_attempt", attributes: [
            "order.id": orderId,
            "order.total": String(totalAmount),
            "order.item_count": String(itemCount)
        ]) { _ in
            addSessionProperty(key: "current_order_id", value: orderId)
            trackUserAction("purchase_attempt", screen: "checkout", properties: [
                "order_id": orderId,
                "total_amount": String(totalAmount),
                "item_count": String(itemCount)
            ])
        }
    }

    func trackPurchaseSuccess(orderId: String, totalAmount: Double, paymentMethod: String) {
        recordSpan(name: "purchase_success", attributes: [
            "order.id": orderId,
            "order.total": String(totalAmount),
            "payment.method": paymentMethod
        ]) { _ in
            removeSessionProperty(key: "current_order_id")
            addSessionProperty(key: "last_successful_order", value: orderId, permanent: true)

            logInfo("Purchase completed successfully", properties: [
                "order_id": orderId,
                "total_amount": String(totalAmount),
                "payment_method": paymentMethod
            ])
        }
    }

    func trackPurchaseFailure(orderId: String, errorMessage: String, failureReason: String) {
        let now = Date()
        recordCompletedSpan(
            name: "purchase_failure",
            startTime: now.addingTimeInterval(-1),
            endTime: now,
            attributes: [
                "order.id": orderId,
                "error.message": errorMessage,
                "failure.reason": failureReason
            ],
            errorCode: .failure
        )

        logError("Purchase failed", properties: [
            "order_id": orderId,
            "error_message": errorMessage,
            "failure_reason": failureReason
        ])
    }

    // MARK: - Authentication

    func trackLoginAttempt(method: String) {
        recordSpan(name: "login_attempt", attributes: ["auth.method": method]) { _ in
            trackUserAction("login_attempt", screen: "authentication", properties: ["method": method])
        }
    }

    func trackLoginSuccess(userId: String, method: String) {
        setUser(id: userId)
        addSessionProperty(key: "auth_method", value: method)

        logInfo("Login successful", properties: [
            "user_id": userId,
            "auth_method": method
        ])
    }

    func trackLoginFailure(method: String, errorMessage: String) {
        let now = Date()
        recordCompletedSpan(
            name: "login_failure",
            startTime: now.addingTimeInterval(-1),
            endTime: now,
            attributes: [
                "auth.method": method,
                "error.message": errorMessage
            ],
            errorCode: .userAbandon
        )

        logError("Login failed", properties: [
            "auth_method": method,
            "error_message": errorMessage
        ])
    }

    // MARK: - Search

    func trackSearchPerformed(query: String, resultCount: Int, filters: [String: String]?) {
        var attributes: [String: String] = [
            "search.query": query,
            "search.result_count": String(resultCount)
        ]
        filters?.forEach { attributes["search.filter.\($0.key)"] = $0.value }

        recordSpan(name: "search_performed", attributes: attributes) { _ in
            var properties = ["query": query, "result_count": String(resultCount)]
            if let filters = filters { properties.merge(filters) { $1 } }
            trackUserAction("search", screen: "search", properties: properties)
        }
    }

    // MARK: - Crash Simulation (Demo Only)

    /// Randomly dispatches to one of 5 distinct crash functions so they
    /// appear as separate crash groups on the Embrace dashboard.
    /// Each function uses EmbraceCrashHelper.crash() to ensure session association.
    func forceEmbraceCrash() {
        let selection = Int.random(in: 0...4)
        switch selection {
        case 0: simulateCartUpdateCrash()
        case 1: simulatePaymentProcessingCrash()
        case 2: simulateProductRecommendationCrash()
        case 3: simulateSearchFilterCrash()
        default: simulateAuthTokenRefreshCrash()
        }
    }

    @inline(never)
    private func simulateCartUpdateCrash() {
        EmbraceIO.shared.log(
            "Cart update failed: quantity sync error",
            severity: .error,
            attributes: ["crash_type": "cart_update", "trigger": "manual_crash_button"]
        )
        addBreadcrumb(message: "Crash in cart quantity update flow")
        EmbraceCrashHelper.crash()
    }

    @inline(never)
    private func simulatePaymentProcessingCrash() {
        EmbraceIO.shared.log(
            "Payment processing failed: unexpected nil response",
            severity: .error,
            attributes: ["crash_type": "payment_processing", "trigger": "manual_crash_button"]
        )
        addBreadcrumb(message: "Crash in payment processing flow")
        EmbraceCrashHelper.crash()
    }

    @inline(never)
    private func simulateProductRecommendationCrash() {
        EmbraceIO.shared.log(
            "Product recommendations failed: index out of range",
            severity: .error,
            attributes: ["crash_type": "product_recommendation", "trigger": "manual_crash_button"]
        )
        addBreadcrumb(message: "Crash in product recommendation engine")
        EmbraceCrashHelper.crash()
    }

    @inline(never)
    private func simulateSearchFilterCrash() {
        EmbraceIO.shared.log(
            "Search filter failed: malformed predicate",
            severity: .error,
            attributes: ["crash_type": "search_filter", "trigger": "manual_crash_button"]
        )
        addBreadcrumb(message: "Crash in search filter application")
        EmbraceCrashHelper.crash()
    }

    @inline(never)
    private func simulateAuthTokenRefreshCrash() {
        EmbraceIO.shared.log(
            "Auth token refresh failed: expired session",
            severity: .error,
            attributes: ["crash_type": "auth_token_refresh", "trigger": "manual_crash_button"]
        )
        addBreadcrumb(message: "Crash in auth token refresh")
        EmbraceCrashHelper.crash()
    }
}
