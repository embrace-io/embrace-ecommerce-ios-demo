//
//  EmbraceService.swift
//  Embrace Ecommerce
//
//  Created by Sergio Rodriguez on 8/7/25.
//
// =============================================================================
// REFERENCE WRAPPER — DESIGN NOTES FOR ANDROID PARITY AND CUSTOMER SHARING
// =============================================================================
//
// This file is a reference wrapper around the Embrace iOS SDK. It is intended
// to be mirrored on Android so the two platforms share the same telemetry
// surface (span names, attribute keys, helper names) and dashboards built on
// top of one work for the other.
//
// The 8 design principles, in order of importance:
//
//   1. WHY WRAP AT ALL
//      - Testability: feature code depends on TelemetryService (a protocol),
//        not EmbraceIO. Tests inject a fake; no SDK in unit tests.
//      - No-op fallback: feature code calls the wrapper at any point in the
//        app lifecycle. The wrapper absorbs SDK readiness; callers never
//        guard with `if (sdkStarted)`.
//      - Single point of change: SDK upgrades, vendor swaps, and language
//        changes (e.g. layering Swift Concurrency on top of OTel) land here.
//
//   2. WRAPPER ARCHITECTURE
//      - Protocol-fronted (TelemetryService) so feature code holds an
//        interface, not a concrete class.
//      - Singleton for convenience here, but inject via DI in production
//        apps (constructor-injected `let telemetry: TelemetryService`).
//      - Behavior before `Embrace.start()` succeeds is well-defined:
//        block-based spans still execute, all other calls no-op safely.
//
//   3. LIFECYCLE & INITIALIZATION
//      - The wrapper does NOT own SDK lifecycle. `Embrace.setup().start()`
//        is called once in `App.init`. Failure to start should not throw
//        out to feature code — wrap and swallow in the call site that
//        starts the SDK.
//      - Apps with consent-delayed capture (e.g. legal treats user ID as
//        PII until login) should defer `Embrace.start()` until after
//        consent. Use MetricKit for pre-consent crash coverage.
//
//   4. SIGNAL AUTHORING — span vs log vs breadcrumb decision
//      - Span: bounded work with start/end and a duration that matters
//        (purchase_attempt, search_performed).
//      - Log: a discrete event with severity (info/warn/error/debug) where
//        the message itself is the payload.
//      - Breadcrumb: a low-cost UX marker for crash/session context. Cheap.
//        Default to breadcrumb when in doubt.
//      - Domain helpers (trackPurchaseAttempt, trackLoginFailure, etc.)
//        compose all three so feature code makes one call and the wrapper
//        emits a consistent shape.
//
//   5. PRIVACY & DATA GOVERNANCE
//      - Use stable, non-PII identifiers via `setUser(id:)`. Avoid passing
//        email/name unless your privacy review permits it.
//      - PII scrubbing belongs at the exporter layer, not at call sites.
//      - On user opt-out: stop the SDK and clear user properties.
//
//   6. OPERATIONAL CONTROLS (not implemented here, but wire-points exist)
//      - Remote config / kill switches: gate `Embrace.start()` and the
//        wrapper's public methods on a feature flag the app already has.
//      - Partial SDK enablement: gate spans/logs/network independently.
//      - Version-targeted sampling: drive sampling rate from app version.
//
//   7. CROSS-PLATFORM PARITY (key divergences with Android)
//      - Session properties: iOS has 3 lifespans (session/process/permanent);
//        Android has 2 (no `.process`). This wrapper exposes only
//        `permanent: Bool` so the API matches Android.
//      - Attributes: iOS Embrace SDK accepts typed OTel AttributeValue;
//        Android only accepts Map<String, String>. Either flatten to
//        strings on iOS too (current approach), or keep typed at the
//        wrapper layer and flatten only inside the Android impl.
//      - SpanType: iOS supports it; Android does not. Don't expose it
//        from the wrapper API.
//      - Span events with attributes: iOS-only — use breadcrumbs instead
//        for cross-platform parity.
//      - Array attributes: silently dropped on iOS, unsupported on Android
//        — don't expose them.
//      - Privacy config: iOS has setPrivacyConfiguration; Android does not.
//
//   8. ANTI-PATTERNS THIS WRAPPER PREVENTS
//      - Holding strong references to spans across view controllers/services
//        and forgetting to end them. Prefer the block-based `recordSpan`.
//      - High-cardinality span/log/attribute names (user IDs, full URLs,
//        timestamps in names). Names live in the wrapper, not in features.
//      - Ending spans you don't own (e.g. a helper ending a span its caller
//        started). Span ownership is one-to-one.
//      - Logging in tight per-frame or per-item loops.
//      - Treating failures as success spans with an error log next to them.
//        Use `errorCode: .failure` so the dashboard sees the failure.
//
// =============================================================================

import Foundation
import EmbraceIO
import EmbraceSemantics
import OpenTelemetryApi

// MARK: - Public Surface
// -----------------------------------------------------------------------------
// PROTOCOL FACADE
// Feature code depends on `TelemetryService`, never `EmbraceIO` directly.
// This is what makes the wrapper testable (inject a fake) and vendor-swappable
// (replace the impl, leave callers untouched).
//
// PARITY: Android should expose an equivalent interface (e.g. ObservabilityProvider
// in Kotlin) with the same method names and parameter shapes. Differences in
// the underlying SDK (Map<String,String>-only attributes, no SpanType, etc.)
// are absorbed inside the Android impl, not in the interface.
// -----------------------------------------------------------------------------

/// Abstraction over Embrace so feature code never imports EmbraceIO directly.
/// Swap the implementation for a mock/no-op in tests.
protocol TelemetryService {
    // Logs
    func logInfo(_ message: String, properties: [String: String]?)
    func logWarning(_ message: String, properties: [String: String]?)
    func logError(_ message: String, properties: [String: String]?)
    func logDebug(_ message: String, properties: [String: String]?)

    // Spans
    func startSpan(name: String) -> OpenTelemetryApi.Span?
    func recordCompletedSpan(
        name: String,
        startTime: Date,
        endTime: Date,
        attributes: [String: String]?,
        errorCode: SpanErrorCode?
    )
    func recordSpan<T>(name: String, attributes: [String: String], block: (Span?) throws -> T) rethrows -> T

    // Events
    func addBreadcrumb(message: String)

    // Metadata (session, process, or permanent scope)
    func addSessionProperty(key: String, value: String, permanent: Bool)
    func removeSessionProperty(key: String)

    // User identity
    func setUser(id: String?, email: String?, name: String?)
    func clearUser()

    // Manual network + push
    func recordNetworkRequest(url: String, method: String, startTime: Date, endTime: Date, statusCode: Int?, errorMessage: String?, traceId: String?)
    func recordPushNotification(userInfo: [AnyHashable: Any])
}

final class EmbraceService: TelemetryService {
    static let shared = EmbraceService()

    private init() {}

    // MARK: - Logs
    // -------------------------------------------------------------------------
    // SEVERITY GUIDANCE
    // - .debug: development-only diagnostics. Filter out in production via
    //   build config or remote config.
    // - .info:  notable but expected events. Use sparingly — breadcrumbs are
    //   cheaper for UX context.
    // - .warn:  recoverable problem. Worth knowing about but not an error.
    // - .error: a real failure that should surface in the dashboard.
    //
    // RULE: log message is a low-cardinality string ("Purchase failed"),
    // not a templated string with IDs ("Purchase failed for order \(id)").
    // Put the IDs in `properties` so aggregation works.
    //
    // PARITY: Android API mirrors this — same severity levels, same
    // properties dictionary. Keep message strings identical across platforms
    // so cross-platform queries work.
    // -------------------------------------------------------------------------

    func logInfo(_ message: String, properties: [String: String]? = nil) {
        Embrace.client?.log(message, severity: .info, attributes: properties ?? [:])
    }

    func logWarning(_ message: String, properties: [String: String]? = nil) {
        Embrace.client?.log(message, severity: .warn, attributes: properties ?? [:])
    }

    func logError(_ message: String, properties: [String: String]? = nil) {
        Embrace.client?.log(message, severity: .error, attributes: properties ?? [:])
    }

    func logDebug(_ message: String, properties: [String: String]? = nil) {
        Embrace.client?.log(message, severity: .debug, attributes: properties ?? [:])
    }

    // MARK: - Spans
    // -------------------------------------------------------------------------
    // THREE PATTERNS, IN ORDER OF PREFERENCE:
    //
    //   1. recordSpan(name:attributes:block:)  ← PREFERRED
    //      Block-based. Auto-ends. Uses static `Embrace.recordSpan(...)` so
    //      the block runs even if Embrace.client is nil (pre-start race).
    //      Safe by default — no way to forget to end the span, no way to
    //      hold a strong reference past its scope.
    //
    //   2. recordCompletedSpan(...)
    //      Use only when the work already happened in the past (replaying
    //      a webhook, recording a failure that wasn't wrapped in a span).
    //      Honors real start/end times and accepts an errorCode so failures
    //      show up as errors in the dashboard.
    //
    //   3. startSpan(name:) -> Span?
    //      Manual start/end. Only use when start and end live in different
    //      functions and there is no way to bridge them with a block.
    //      Caller owns calling `.end()`. ANTI-PATTERN: storing this on a
    //      view controller and ending it in `deinit` — the deinit may
    //      never run, or run on the wrong thread.
    //
    // NAMING CONVENTION (enforced here, not at call sites):
    //   - Lowercase, snake_case: `purchase_attempt`, not `purchaseAttempt`.
    //   - Low cardinality: `product_view`, NEVER `product_view_<productId>`.
    //   - Attribute keys are dotted: `order.id`, `cart.quantity`,
    //     `http.status_code` (OTel-style).
    //
    // FAILURES MUST BE MARKED:
    //   recordCompletedSpan(..., errorCode: .failure) makes the span show up
    //   as errored in the dashboard. A successful span with an error log
    //   next to it is invisible to most charts.
    //
    // PARITY: Android exposes the same three patterns. Note that Android's
    // EmbraceSpan.addAttribute() takes only String — flatten typed values
    // inside the Android impl, not at call sites.
    // -------------------------------------------------------------------------

    /// Returns a started span. Caller owns calling `.end()` (or `.end(errorCode:)`).
    func startSpan(name: String) -> OpenTelemetryApi.Span? {
        Embrace.client?.buildSpan(name: name, type: .performance).startSpan()
    }

    /// Records a span that already happened. Honors real start/end times and
    /// optionally marks it as failed so it shows up as an error in the dashboard.
    func recordCompletedSpan(
        name: String,
        startTime: Date,
        endTime: Date,
        attributes: [String: String]? = nil,
        errorCode: SpanErrorCode? = nil
    ) {
        Embrace.client?.recordCompletedSpan(
            name: name,
            type: .performance,
            parent: nil,
            startTime: startTime,
            endTime: endTime,
            attributes: attributes ?? [:],
            events: [],
            errorCode: errorCode
        )
    }

    /// Block-based span. Preferred for short synchronous work — auto-ends,
    /// and the block still runs if Embrace.client is nil (e.g., pre-start).
    @discardableResult
    func recordSpan<T>(
        name: String,
        attributes: [String: String] = [:],
        block: (Span?) throws -> T
    ) rethrows -> T {
        try Embrace.recordSpan(name: name, type: .performance, attributes: attributes, block: block)
    }

    // MARK: - Breadcrumbs
    // -------------------------------------------------------------------------
    // BREADCRUMBS ARE THE DEFAULT for UX context. They are cheap (cost-wise),
    // attach to the session/crash for debugging, and require no schema.
    //
    // DECISION TREE:
    //   - "User did X on screen Y"          → breadcrumb
    //   - "X happened with severity Z"      → log
    //   - "X took N ms and may have failed" → span
    //
    // PARITY: Android's addBreadcrumb(message: String) is the equivalent.
    // Note: Android does NOT support standalone span events with attributes,
    // so anything you'd model as a span event on iOS becomes a breadcrumb
    // for cross-platform parity.
    // -------------------------------------------------------------------------

    func addBreadcrumb(message: String) {
        Embrace.client?.add(event: .breadcrumb(message))
    }

    // MARK: - Session Properties
    // -------------------------------------------------------------------------
    // LIFESPAN OPTIONS (iOS):
    //   .session    — cleared at session end (default)
    //   .process    — cleared at process end (iOS only — ANDROID HAS NO EQUIVALENT)
    //   .permanent  — persists across sessions until explicitly removed
    //
    // This wrapper exposes only `permanent: Bool` so the API matches Android.
    // If you need `.process` scope on iOS, add a separate enum here and
    // document the divergence — Android cannot mirror it.
    //
    // SDK LIMIT: ~100 session properties cap. The wrapper is the right place
    // to enforce a domain whitelist if your app risks exceeding this.
    //
    // ANTI-PATTERN: setting a session property per item in a list, or per
    // network response, blows the cap fast.
    // -------------------------------------------------------------------------

    func addSessionProperty(key: String, value: String, permanent: Bool = false) {
        try? Embrace.client?.metadata.addProperty(
            key: key,
            value: value,
            lifespan: permanent ? .permanent : .session
        )
    }

    func removeSessionProperty(key: String) {
        try? Embrace.client?.metadata.removeProperty(key: key)
    }

    // MARK: - User Identity
    // -------------------------------------------------------------------------
    // PRIVACY GUIDANCE (this is the most-asked privacy question):
    //   - Prefer a stable, opaque, non-PII identifier for `id` (your internal
    //     user UUID, not email or username).
    //   - Pass `email` / `name` only if your privacy review explicitly allows it.
    //     They show up in dashboards and exports.
    //   - On opt-out: call `clearUser()` AND stop the SDK if your consent
    //     model requires it. Clearing user fields alone does not stop
    //     telemetry from being collected.
    //   - Set the user identifier as soon as you have it (typically right
    //     after login / consent), not at app launch.
    //
    // PARITY: Android exposes setUserIdentifier(id) / setUserEmail(email) /
    // setUsername(name) and clearUserIdentifier(). Wrap them the same way.
    // -------------------------------------------------------------------------

    /// Sets built-in user fields (id/email/name). Persists across sessions
    /// until `clearUser()` is called. Pass `nil` to leave a field unchanged.
    func setUser(id: String?, email: String? = nil, name: String? = nil) {
        guard let metadata = Embrace.client?.metadata else { return }
        if let id = id { metadata.userIdentifier = id }
        if let email = email { metadata.userEmail = email }
        if let name = name { metadata.userName = name }
    }

    func clearUser() {
        Embrace.client?.metadata.clearUserProperties()
    }

    // MARK: - Network Monitoring
    // -------------------------------------------------------------------------
    // The SDK's URLSessionCaptureService auto-captures URLSession traffic on
    // iOS. Android has an equivalent OkHttp/HttpURLConnection capture.
    //
    // USE THIS METHOD ONLY for custom transports the SDK cannot see:
    //   - third-party HTTP clients that bypass URLSession / OkHttp
    //   - gRPC, WebSocket, or other non-HTTP protocols
    //   - native networking stacks
    //
    // ANTI-PATTERN: calling this for every URLSession request "to be safe"
    // — you'll double-record everything the SDK already captures.
    //
    // PARITY: Android wrapper should expose the same method with the same
    // attribute keys (http.url, http.method, http.status_code) so dashboards
    // built on these spans work for both platforms.
    // -------------------------------------------------------------------------

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

        Embrace.client?.recordCompletedSpan(
            name: "network_request",
            type: .networkRequest,
            parent: nil,
            startTime: startTime,
            endTime: endTime,
            attributes: attributes,
            events: [],
            errorCode: errorMessage == nil ? nil : .failure
        )
    }

    // MARK: - Push Notifications
    // -------------------------------------------------------------------------
    // Pass the RAW `userInfo` dictionary. Don't pre-parse it — the SDK's
    // `PushNotificationEvent.push(userInfo:)` extracts the standard `aps`
    // payload (title, body, category, badge) for you and produces a
    // consistent event shape.
    //
    // ANTI-PATTERN: building your own attributes dictionary from `userInfo`
    // and emitting a custom log. You'll get inconsistent shapes per app
    // and dashboards won't generalize.
    //
    // PARITY: Android has equivalent push notification handling — the
    // wrapper should accept the raw RemoteMessage / Bundle and let the
    // Android SDK parse it.
    // -------------------------------------------------------------------------

    /// Preferred: pass the raw `userInfo` from
    /// `didReceiveRemoteNotification` / `UNUserNotificationCenterDelegate`.
    /// The SDK parses the `aps` payload (title/body/category/badge) for you.
    func recordPushNotification(userInfo: [AnyHashable: Any]) {
        do {
            if let event = try? PushNotificationEvent.push(userInfo: userInfo) {
                Embrace.client?.add(event: event)
            }
        }
        addBreadcrumb(message: "Push notification received")
    }

    // MARK: - User Journey
    // -------------------------------------------------------------------------
    // DOMAIN HELPERS — THE REASON THIS WRAPPER EXISTS.
    //
    // Each helper composes span + breadcrumb + log + session property into a
    // single call site. Feature code calls one method; the wrapper emits a
    // consistent shape across the entire app.
    //
    // WHY THIS MATTERS:
    //   - Names live here, once. Features can't drift to `view_product`
    //     vs `product_view` vs `productView`.
    //   - Failure handling lives here. trackPurchaseFailure marks the span
    //     with errorCode: .failure so it shows up correctly in the dashboard.
    //   - Schema lives here. Every helper uses the same attribute keys
    //     (order.id, product.id, cart.quantity).
    //
    // PARITY: Android should expose the SAME helper names with the SAME span
    // names and attribute keys. This is the contract that lets you build
    // one dashboard query that works for both platforms.
    //
    // SCALE: keep helpers small (4-10 lines). When a helper grows, it's
    // usually a sign that it should be split into two narrower helpers,
    // not that it should grow more parameters.
    // -------------------------------------------------------------------------

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
    // -------------------------------------------------------------------------
    // DEMO CODE — DELETE IN A REAL APP.
    //
    // Five distinct @inline(never) functions ensure each crash gets its own
    // stack trace and groups separately in the Embrace dashboard. Each
    // function emits a log + breadcrumb before crashing so the session has
    // context when you open the crash.
    //
    // Each crash uses `Embrace.client?.crash()` (not `fatalError`) so the
    // crash is associated with the current Embrace session. A native
    // `fatalError()` may not flush session context before the process dies.
    //
    // PARITY: Android wrapper should have the same demo helpers using
    // Embrace.getInstance().crash() — same number of distinct crash sites,
    // same naming, so demos look identical on both platforms.
    // -------------------------------------------------------------------------

    /// Randomly dispatches to one of 5 distinct crash functions so they
    /// appear as separate crash groups on the Embrace dashboard.
    /// Each function uses Embrace.client?.crash() to ensure session association.
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
        Embrace.client?.log(
            "Cart update failed: quantity sync error",
            severity: .error,
            attributes: ["crash_type": "cart_update", "trigger": "manual_crash_button"]
        )
        addBreadcrumb(message: "Crash in cart quantity update flow")
        Embrace.client?.crash()
    }

    @inline(never)
    private func simulatePaymentProcessingCrash() {
        Embrace.client?.log(
            "Payment processing failed: unexpected nil response",
            severity: .error,
            attributes: ["crash_type": "payment_processing", "trigger": "manual_crash_button"]
        )
        addBreadcrumb(message: "Crash in payment processing flow")
        Embrace.client?.crash()
    }

    @inline(never)
    private func simulateProductRecommendationCrash() {
        Embrace.client?.log(
            "Product recommendations failed: index out of range",
            severity: .error,
            attributes: ["crash_type": "product_recommendation", "trigger": "manual_crash_button"]
        )
        addBreadcrumb(message: "Crash in product recommendation engine")
        Embrace.client?.crash()
    }

    @inline(never)
    private func simulateSearchFilterCrash() {
        Embrace.client?.log(
            "Search filter failed: malformed predicate",
            severity: .error,
            attributes: ["crash_type": "search_filter", "trigger": "manual_crash_button"]
        )
        addBreadcrumb(message: "Crash in search filter application")
        Embrace.client?.crash()
    }

    @inline(never)
    private func simulateAuthTokenRefreshCrash() {
        Embrace.client?.log(
            "Auth token refresh failed: expired session",
            severity: .error,
            attributes: ["crash_type": "auth_token_refresh", "trigger": "manual_crash_button"]
        )
        addBreadcrumb(message: "Crash in auth token refresh")
        Embrace.client?.crash()
    }
}
