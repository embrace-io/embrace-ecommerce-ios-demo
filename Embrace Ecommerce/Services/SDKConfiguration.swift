//
//  SDKConfiguration.swift
//  Embrace Ecommerce
//
//  Created by Sergio Rodriguez on 8/7/25.
//

import Foundation

struct SDKConfiguration {
    
    // MARK: - Embrace Configuration
    
    struct Embrace {
        // REQUIRED: Replace with your Embrace App ID from dash.embrace.io
        // Get your App ID: https://dash.embrace.io -> Create New App -> Copy App ID
        static let appId = "YOUR_EMBRACE_APP_ID"  // TODO: Replace this!
        
        // Development settings for comprehensive telemetry
        static let logLevel = "info"
        static let networkSpansForwardingEnabled = true
        static let automaticViewCaptureEnabled = true
        
        // Session properties for dogfooding identification
        static let sessionProperties: [String: String] = [
            "app_type": "dogfooding_ecommerce",
            "sdk_test_mode": "enabled",
            "environment": "development"
        ]
    }
    
    // MARK: - Firebase Configuration
    
    struct Firebase {
        // Firebase is configured automatically via GoogleService-Info.plist
        // Add any custom Firebase settings here if needed
        static let analyticsEnabled = true
        static let crashlyticsEnabled = true
        static let performanceMonitoringEnabled = true
    }
    
    // MARK: - Mixpanel Configuration

    struct Mixpanel {
        // TODO: Replace with your actual Mixpanel project token
        // Get your token from: https://mixpanel.com/settings/project
        static let projectToken = "YOUR_MIXPANEL_PROJECT_TOKEN"
        static let trackAutomaticEvents = true

        // Development fallback
        static var isConfigured: Bool {
            return projectToken != "YOUR_MIXPANEL_PROJECT_TOKEN" && !projectToken.isEmpty
        }
    }
    
    // MARK: - Stripe Configuration
    
    struct Stripe {
        // Test publishable key - replace with your actual test key
        static let publishableKey = "pk_test_51234567890abcdef"
        static let merchantIdentifier = "merchant.com.embrace.ecommerce"
    }
    
    // MARK: - Google Sign-In Configuration
    
    struct GoogleSignIn {
        // Client ID will be read from GoogleService-Info.plist
        // Fallback for development without actual Google project
        static let fallbackClientId = "123456789-abcdefg.apps.googleusercontent.com"
    }
    
    // MARK: - Network Configuration
    
    struct Network {
        static let baseURL = "https://api.embrace-ecommerce.mock"
        static let timeout: TimeInterval = 30.0
        static let retryAttempts = 3
        
        // Mock server settings for realistic network behavior
        static let simulateNetworkDelay = true
        static let averageNetworkDelay: TimeInterval = 0.5
        static let networkErrorRate: Double = 0.05 // 5% error rate for testing
    }
    
    // MARK: - Feature Flags
    
    struct FeatureFlags {
        static let enableBiometricAuth = true
        static let enablePushNotifications = true
        static let enableAdvancedLogging = true
        static let enablePerformanceMonitoring = true
        
        // Dogfooding specific features
        static let enableNetworkDebugView = true
        static let enableTelemetryDebugView = true
        static let enableCrashSimulation = true
        static let enableSlowNetworkSimulation = true
    }
    
    // MARK: - Validation Methods
    
    static func validateConfiguration() -> [String] {
        var warnings: [String] = []

        if Embrace.appId == "YOUR_EMBRACE_APP_ID" || Embrace.appId.isEmpty {
            warnings.append("WARNING: Embrace App ID not configured - using placeholder")
        }

        if !Mixpanel.isConfigured {
            warnings.append("WARNING: Mixpanel project token not configured - using mock")
        }

        if Stripe.publishableKey.hasPrefix("pk_test_51234567890") {
            warnings.append("WARNING: Stripe publishable key not configured - using placeholder")
        }

        return warnings
    }
    
    static func printConfigurationStatus() {
        print("\nSDK Configuration Status:")
        print("=============================")

        let warnings = validateConfiguration()

        if warnings.isEmpty {
            print("All SDKs configured properly")
        } else {
            print("Configuration warnings:")
            warnings.forEach { print($0) }
            print("\nNote: App will still function with placeholder values for testing")
        }

        print("\nSDK Versions:")
        print("- Embrace SDK: 6.13.0")
        print("- Firebase SDK: 12.1.0")
        print("- Stripe SDK: 24.19.0")
        print("- Google Sign-In: 9.0.0")
        print("- Mixpanel: Latest\n")
    }
}

// MARK: - Environment-specific Configuration

extension SDKConfiguration {
    
    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var shouldUseVerboseLogging: Bool {
        return isDebugMode || FeatureFlags.enableAdvancedLogging
    }
    
    static var shouldEnableNetworkMocking: Bool {
        return isDebugMode
    }
}
