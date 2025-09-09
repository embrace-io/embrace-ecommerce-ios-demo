//
//  MixpanelAnalyticsService.swift
//  Embrace Ecommerce
//
//  Created by Sergio Rodriguez on 9/9/25.
//

import Foundation
import Mixpanel

@MainActor
final class MixpanelAnalyticsService: ObservableObject {
    static let shared = MixpanelAnalyticsService()
    
    private let mixpanel = Mixpanel.mainInstance()
    
    private init() {}
    
    // MARK: - User Management
    
    func identifyUser(userId: String, email: String? = nil) {
        mixpanel.identify(distinctId: userId)
        
        var properties: [String: MixpanelType] = [:]
        if let email = email {
            properties["email"] = email
        }
        properties["first_seen"] = Date()
        properties["platform"] = "iOS"
        
        mixpanel.people.set(properties: properties)
        
        EmbraceService.shared.logInfo("User identified in Mixpanel", properties: [
            "user_id": userId,
            "has_email": email != nil ? "true" : "false"
        ])
    }
    
    func updateUserProfile(email: String? = nil, name: String? = nil, plan: String? = nil) {
        var properties: [String: MixpanelType] = [:]
        
        if let email = email {
            properties["email"] = email
        }
        if let name = name {
            properties["name"] = name
        }
        if let plan = plan {
            properties["plan"] = plan
        }
        
        properties["profile_updated"] = Date()
        
        mixpanel.people.set(properties: properties)
    }
    
    func resetUserSession() {
        mixpanel.reset()
        EmbraceService.shared.logInfo("Mixpanel user session reset")
    }
    
    // MARK: - E-commerce Events
    
    func trackProductViewed(productId: String, productName: String, category: String?, price: Double?) {
        var properties: [String: MixpanelType] = [
            "product_id": productId,
            "product_name": productName,
            "timestamp": Date()
        ]
        
        if let category = category {
            properties["category"] = category
        }
        if let price = price {
            properties["price"] = price
        }
        
        mixpanel.track(event: "Product Viewed", properties: properties)
    }
    
    func trackProductAddedToCart(productId: String, productName: String, price: Double, quantity: Int) {
        let properties: [String: MixpanelType] = [
            "product_id": productId,
            "product_name": productName,
            "price": price,
            "quantity": quantity,
            "total_value": price * Double(quantity),
            "timestamp": Date()
        ]
        
        mixpanel.track(event: "Product Added to Cart", properties: properties)
        
        mixpanel.people.trackCharge(amount: price * Double(quantity), properties: [
            "product_id": productId,
            "quantity": quantity
        ])
    }
    
    func trackProductRemovedFromCart(productId: String, productName: String, price: Double, quantity: Int) {
        let properties: [String: MixpanelType] = [
            "product_id": productId,
            "product_name": productName,
            "price": price,
            "quantity": quantity,
            "total_value": price * Double(quantity),
            "timestamp": Date()
        ]
        
        mixpanel.track(event: "Product Removed from Cart", properties: properties)
    }
    
    func trackCartViewed(itemCount: Int, totalValue: Double) {
        let properties: [String: MixpanelType] = [
            "item_count": itemCount,
            "total_value": totalValue,
            "timestamp": Date()
        ]
        
        mixpanel.track(event: "Cart Viewed", properties: properties)
    }
    
    func trackCheckoutStarted(itemCount: Int, totalValue: Double) {
        let properties: [String: MixpanelType] = [
            "item_count": itemCount,
            "total_value": totalValue,
            "checkout_step": "started",
            "timestamp": Date()
        ]
        
        mixpanel.track(event: "Checkout Started", properties: properties)
    }
    
    func trackCheckoutStepCompleted(step: String, itemCount: Int, totalValue: Double) {
        let properties: [String: MixpanelType] = [
            "checkout_step": step,
            "item_count": itemCount,
            "total_value": totalValue,
            "timestamp": Date()
        ]
        
        mixpanel.track(event: "Checkout Step Completed", properties: properties)
    }
    
    func trackOrderCompleted(orderId: String, totalValue: Double, itemCount: Int, paymentMethod: String) {
        let properties: [String: MixpanelType] = [
            "order_id": orderId,
            "total_value": totalValue,
            "item_count": itemCount,
            "payment_method": paymentMethod,
            "timestamp": Date()
        ]
        
        mixpanel.track(event: "Order Completed", properties: properties)
        
        mixpanel.people.trackCharge(amount: totalValue, properties: [
            "order_id": orderId,
            "payment_method": paymentMethod
        ])
        
        mixpanel.people.increment(properties: [
            "total_orders": 1,
            "total_spent": totalValue
        ])
    }
    
    // MARK: - User Journey Events
    
    func trackScreenView(screenName: String, source: String? = nil) {
        var properties: [String: MixpanelType] = [
            "screen_name": screenName,
            "timestamp": Date()
        ]
        
        if let source = source {
            properties["source"] = source
        }
        
        mixpanel.track(event: "Screen View", properties: properties)
    }
    
    func trackSearchPerformed(query: String, resultCount: Int) {
        let properties: [String: MixpanelType] = [
            "search_query": query,
            "result_count": resultCount,
            "timestamp": Date()
        ]
        
        mixpanel.track(event: "Search Performed", properties: properties)
    }
    
    func trackFilterApplied(filterType: String, filterValue: String, resultCount: Int) {
        let properties: [String: MixpanelType] = [
            "filter_type": filterType,
            "filter_value": filterValue,
            "result_count": resultCount,
            "timestamp": Date()
        ]
        
        mixpanel.track(event: "Filter Applied", properties: properties)
    }
    
    // MARK: - Authentication Events
    
    func trackUserSignUp(method: String, success: Bool) {
        let properties: [String: MixpanelType] = [
            "signup_method": method,
            "success": success,
            "timestamp": Date()
        ]
        
        mixpanel.track(event: "User Sign Up", properties: properties)
        
        if success {
            mixpanel.people.setOnce(properties: [
                "first_signup_method": method,
                "signup_date": Date()
            ])
        }
    }
    
    func trackUserSignIn(method: String, success: Bool) {
        let properties: [String: MixpanelType] = [
            "signin_method": method,
            "success": success,
            "timestamp": Date()
        ]
        
        mixpanel.track(event: "User Sign In", properties: properties)
        
        if success {
            mixpanel.people.set(properties: [
                "last_login": Date()
            ])
        }
    }
    
    func trackUserSignOut() {
        mixpanel.track(event: "User Sign Out", properties: [
            "timestamp": Date()
        ])
        
        mixpanel.people.set(properties: [
            "last_logout": Date()
        ])
    }
    
    // MARK: - Error and Performance Tracking
    
    func trackError(error: String, context: String? = nil, fatal: Bool = false) {
        var properties: [String: MixpanelType] = [
            "error_message": error,
            "is_fatal": fatal,
            "timestamp": Date()
        ]
        
        if let context = context {
            properties["error_context"] = context
        }
        
        mixpanel.track(event: "Error Occurred", properties: properties)
        
        if fatal {
            mixpanel.people.increment(properties: ["fatal_errors": 1])
        } else {
            mixpanel.people.increment(properties: ["non_fatal_errors": 1])
        }
    }
    
    func trackPerformanceMetric(metric: String, value: Double, context: String? = nil) {
        var properties: [String: MixpanelType] = [
            "metric_name": metric,
            "metric_value": value,
            "timestamp": Date()
        ]
        
        if let context = context {
            properties["context"] = context
        }
        
        mixpanel.track(event: "Performance Metric", properties: properties)
    }
    
    // MARK: - Custom Events
    
    func trackCustomEvent(eventName: String, properties: [String: Any] = [:]) {
        var mixpanelProperties: [String: MixpanelType] = [
            "timestamp": Date()
        ]
        
        for (key, value) in properties {
            if let mixpanelValue = convertToMixpanelType(value) {
                mixpanelProperties[key] = mixpanelValue
            }
        }
        
        mixpanel.track(event: eventName, properties: mixpanelProperties)
    }
    
    // MARK: - Helper Methods
    
    private func convertToMixpanelType(_ value: Any) -> MixpanelType? {
        switch value {
        case let stringValue as String:
            return stringValue
        case let intValue as Int:
            return intValue
        case let doubleValue as Double:
            return doubleValue
        case let boolValue as Bool:
            return boolValue
        case let dateValue as Date:
            return dateValue
        default:
            return String(describing: value)
        }
    }
    
    // MARK: - Batch Operations
    
    func flush() {
        mixpanel.flush()
    }
    
    func setSuperProperties(_ properties: [String: MixpanelType]) {
        mixpanel.registerSuperProperties(properties)
    }
    
    func removeSuperProperty(_ key: String) {
        mixpanel.unregisterSuperProperty(key)
    }
}

// MARK: - E-commerce Event Extensions

extension MixpanelAnalyticsService {
    
    func trackProductListViewed(category: String?, sortBy: String?, itemCount: Int) {
        var properties: [String: MixpanelType] = [
            "item_count": itemCount,
            "timestamp": Date()
        ]
        
        if let category = category {
            properties["category"] = category
        }
        if let sortBy = sortBy {
            properties["sort_by"] = sortBy
        }
        
        mixpanel.track(event: "Product List Viewed", properties: properties)
    }
    
    func trackWishlistAction(action: String, productId: String, productName: String) {
        let properties: [String: MixpanelType] = [
            "action": action,
            "product_id": productId,
            "product_name": productName,
            "timestamp": Date()
        ]
        
        mixpanel.track(event: "Wishlist Action", properties: properties)
        
        if action == "added" {
            mixpanel.people.increment(properties: ["wishlist_items": 1])
        } else if action == "removed" {
            mixpanel.people.increment(properties: ["wishlist_items": -1])
        }
    }
    
    func trackPaymentMethodSelected(method: String, isDefault: Bool = false) {
        let properties: [String: MixpanelType] = [
            "payment_method": method,
            "is_default": isDefault,
            "timestamp": Date()
        ]
        
        mixpanel.track(event: "Payment Method Selected", properties: properties)
        
        mixpanel.people.set(properties: [
            "preferred_payment_method": method
        ])
    }
    
    func trackShippingMethodSelected(method: String, cost: Double, estimatedDays: Int?) {
        var properties: [String: MixpanelType] = [
            "shipping_method": method,
            "shipping_cost": cost,
            "timestamp": Date()
        ]
        
        if let estimatedDays = estimatedDays {
            properties["estimated_delivery_days"] = estimatedDays
        }
        
        mixpanel.track(event: "Shipping Method Selected", properties: properties)
    }
}