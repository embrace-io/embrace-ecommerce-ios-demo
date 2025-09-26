//
//  EmbraceService.swift
//  Embrace Ecommerce
//
//  Created by Sergio Rodriguez on 8/7/25.
//

import Foundation
import EmbraceIO
import OpenTelemetryApi

protocol TelemetryService {
    func logInfo(_ message: String, properties: [String: String]?)
    func logWarning(_ message: String, properties: [String: String]?)
    func logError(_ message: String, properties: [String: String]?)
    func logDebug(_ message: String, properties: [String: String]?)
    
    func startSpan(name: String) -> OpenTelemetryApi.Span?
    func recordCompletedSpan(name: String, startTime: Date, endTime: Date, attributes: [String: String]?)
    
    func addBreadcrumb(message: String)
    func addSessionProperty(key: String, value: String, permanent: Bool)
    func removeSessionProperty(key: String)
    
    func recordNetworkRequest(url: String, method: String, startTime: Date, endTime: Date, statusCode: Int?, errorMessage: String?, traceId: String?)
    func recordPushNotification(title: String?, body: String?, topic: String?, messageId: String?)
}

final class EmbraceService: TelemetryService {
    static let shared = EmbraceService()
    
    private init() {}
    
    // MARK: - Logging Methods
    
    func logInfo(_ message: String, properties: [String: String]? = nil) {
        Embrace.client?.log(
            message,
            severity: .info,
            attributes: properties ?? [:]
        )
    }
    
    func logWarning(_ message: String, properties: [String: String]? = nil) {
        Embrace.client?.log(
            message,
            severity: .warn,
            attributes: properties ?? [:]
        )
    }
    
    func logError(_ message: String, properties: [String: String]? = nil) {
        Embrace.client?.log(
            message,
            severity: .error,
            attributes: properties ?? [:]
        )
    }
    
    func logDebug(_ message: String, properties: [String: String]? = nil) {
        Embrace.client?.log(
            message,
            severity: .debug,
            attributes: properties ?? [:]
        )
    }
    
    // MARK: - Custom Spans
    
    func startSpan(name: String) -> OpenTelemetryApi.Span? {
        return Embrace.client?.buildSpan(name: name, type: .performance)
            .startSpan()
    }
    
    func recordCompletedSpan(name: String, startTime: Date, endTime: Date, attributes: [String: String]? = nil) {
        let span = Embrace.client?.buildSpan(name: name, type: .performance)
            .startSpan()
        
        if let attributes = attributes {
            for (key, value) in attributes {
                span?.setAttribute(key: key, value: value)
            }
        }
        
        span?.end()
    }
    
    // MARK: - Breadcrumbs
    
    func addBreadcrumb(message: String) {
        Embrace.client?.add(event: .breadcrumb(message))
    }
    
    // MARK: - Session Properties
    
    func addSessionProperty(key: String, value: String, permanent: Bool = false) {
        // Note: Session property API needs to be checked for Embrace 6.x
        // Embrace.client?.addSessionProperty(key, value: value, permanent: permanent)
    }
    
    func removeSessionProperty(key: String) {
        // Note: Session property API needs to be checked for Embrace 6.x
        // Embrace.client?.removeSessionProperty(key)
    }
    
    // MARK: - Network Monitoring
    
    func recordNetworkRequest(url: String, method: String, startTime: Date, endTime: Date, statusCode: Int?, errorMessage: String?, traceId: String?) {
        let span = Embrace.client?.buildSpan(name: "network_request", type: .networkRequest).startSpan()
        
        span?.setAttribute(key: "http.url", value: url)
        span?.setAttribute(key: "http.method", value: method)
        
        if let statusCode = statusCode {
            span?.setAttribute(key: "http.status_code", value: String(statusCode))
        }
        
        if let traceId = traceId {
            span?.setAttribute(key: "http.trace_id", value: traceId)
        }
        
        if let errorMessage = errorMessage {
            // Note: Span status API needs to be checked for Embrace 6.x
            // span?.setStatus(.error, description: errorMessage)
            span?.setAttribute(key: "error.message", value: errorMessage)
        }
        
        span?.end()
    }
    
    // MARK: - Push Notifications
    
    func recordPushNotification(title: String?, body: String?, topic: String?, messageId: String?) {
        addBreadcrumb(message: "Push notification received")
        
        let attributes: [String: String] = [
            "push.title": title ?? "",
            "push.body": body ?? "",
            "push.topic": topic ?? "",
            "push.message_id": messageId ?? ""
        ].compactMapValues { $0.isEmpty ? nil : $0 }
        
        logInfo("Push notification received", properties: attributes)
    }
    
    // MARK: - User Journey Tracking
    
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
    
    // MARK: - E-commerce Specific Tracking
    
    func trackProductView(productId: String, productName: String, category: String?, price: Double?) {
        let span = Embrace.client?.buildSpan(name: "product_view", type: .performance).startSpan()
        
        span?.setAttribute(key: "product.id", value: productId)
        span?.setAttribute(key: "product.name", value: productName)
        if let category = category {
            span?.setAttribute(key: "product.category", value: category)
        }
        if let price = price {
            span?.setAttribute(key: "product.price", value: String(price))
        }
        
        trackUserAction("product_view", screen: "product_detail", properties: [
            "product_id": productId,
            "product_name": productName
        ])
        
        span?.end()
    }
    
    func trackAddToCart(productId: String, quantity: Int, price: Double) {
        let span = Embrace.client?.buildSpan(name: "add_to_cart", type: .performance).startSpan()
        
        span?.setAttribute(key: "product.id", value: productId)
        span?.setAttribute(key: "cart.quantity", value: String(quantity))
        span?.setAttribute(key: "cart.item_value", value: String(price))
        
        trackUserAction("add_to_cart", screen: "product_detail", properties: [
            "product_id": productId,
            "quantity": String(quantity),
            "value": String(price)
        ])
        
        span?.end()
    }
    
    func trackPurchaseAttempt(orderId: String, totalAmount: Double, itemCount: Int) {
        let span = Embrace.client?.buildSpan(name: "purchase_attempt", type: .performance).startSpan()
        
        span?.setAttribute(key: "order.id", value: orderId)
        span?.setAttribute(key: "order.total", value: String(totalAmount))
        span?.setAttribute(key: "order.item_count", value: String(itemCount))
        
        addSessionProperty(key: "current_order_id", value: orderId)
        
        trackUserAction("purchase_attempt", screen: "checkout", properties: [
            "order_id": orderId,
            "total_amount": String(totalAmount),
            "item_count": String(itemCount)
        ])
        
        span?.end()
    }
    
    func trackPurchaseSuccess(orderId: String, totalAmount: Double, paymentMethod: String) {
        recordCompletedSpan(
            name: "purchase_success",
            startTime: Date().addingTimeInterval(-1),
            endTime: Date(),
            attributes: [
                "order.id": orderId,
                "order.total": String(totalAmount),
                "payment.method": paymentMethod
            ]
        )
        
        removeSessionProperty(key: "current_order_id")
        addSessionProperty(key: "last_successful_order", value: orderId, permanent: true)
        
        logInfo("Purchase completed successfully", properties: [
            "order_id": orderId,
            "total_amount": String(totalAmount),
            "payment_method": paymentMethod
        ])
    }
    
    func trackPurchaseFailure(orderId: String, errorMessage: String, failureReason: String) {
        recordCompletedSpan(
            name: "purchase_failure",
            startTime: Date().addingTimeInterval(-1),
            endTime: Date(),
            attributes: [
                "order.id": orderId,
                "error.message": errorMessage,
                "failure.reason": failureReason
            ]
        )
        
        logError("Purchase failed", properties: [
            "order_id": orderId,
            "error_message": errorMessage,
            "failure_reason": failureReason
        ])
    }
    
    // MARK: - Authentication Tracking
    
    func trackLoginAttempt(method: String) {
        let span = Embrace.client?.buildSpan(name: "login_attempt", type: .performance).startSpan()
        span?.setAttribute(key: "auth.method", value: method)
        
        trackUserAction("login_attempt", screen: "authentication", properties: ["method": method])
        
        span?.end()
    }
    
    func trackLoginSuccess(userId: String, method: String) {
        addSessionProperty(key: "user_id", value: userId, permanent: true)
        addSessionProperty(key: "auth_method", value: method)
        
        logInfo("Login successful", properties: [
            "user_id": userId,
            "auth_method": method
        ])
    }
    
    func trackLoginFailure(method: String, errorMessage: String) {
        recordCompletedSpan(
            name: "login_failure",
            startTime: Date().addingTimeInterval(-1),
            endTime: Date(),
            attributes: [
                "auth.method": method,
                "error.message": errorMessage
            ]
        )
        
        logError("Login failed", properties: [
            "auth_method": method,
            "error_message": errorMessage
        ])
    }
    
    // MARK: - Search Tracking
    
    func trackSearchPerformed(query: String, resultCount: Int, filters: [String: String]?) {
        let span = Embrace.client?.buildSpan(name: "search_performed", type: .performance).startSpan()
        
        span?.setAttribute(key: "search.query", value: query)
        span?.setAttribute(key: "search.result_count", value: String(resultCount))
        
        if let filters = filters {
            for (key, value) in filters {
                span?.setAttribute(key: "search.filter.\(key)", value: value)
            }
        }
        
        var properties = ["query": query, "result_count": String(resultCount)]
        if let filters = filters {
            properties.merge(filters) { $1 }
        }
        
        trackUserAction("search", screen: "search", properties: properties)
        
        span?.end()
    }
}
