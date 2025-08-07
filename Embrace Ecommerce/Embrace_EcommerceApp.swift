//
//  Embrace_EcommerceApp.swift
//  Embrace Ecommerce
//
//  Created by Sergio Rodriguez on 8/6/25.
//

import SwiftUI
import EmbraceIO
import GoogleSignIn
import Stripe
import Firebase
import Mixpanel

@main
struct Embrace_EcommerceApp: App {
    init() {
        // Initialize Firebase first (required for Firebase services)
        configureFirebase()
        
        // Initialize Embrace SDK with comprehensive options
        configureEmbrace()
        
        // Initialize Mixpanel
        configureMixpanel()
        
        // Configure Google Sign-In
        configureGoogleSignIn()
        
        // Initialize Stripe
        configureStripe()
        
        // Print configuration status and validate setup
        SDKConfiguration.printConfigurationStatus()
        
        // Log successful initialization
        EmbraceService.shared.logInfo("App initialization completed", properties: [
            "embrace_version": "6.13.0",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "configuration_warnings": SDKConfiguration.validateConfiguration().joined(separator: ", ")
        ])
        
        // Run SDK compatibility tests in debug mode
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            SDKCompatibilityTest.shared.runCompatibilityTests()
        }
        #endif
    }
    
    private func configureFirebase() {
        // Check if GoogleService-Info.plist exists before configuring Firebase
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
            print("✅ Firebase configured successfully")
            EmbraceService.shared.addSessionProperty(key: "firebase_configured", value: "true")
        } else {
            print("⚠️ GoogleService-Info.plist not found. Firebase disabled for this session.")
            print("   To enable Firebase, add GoogleService-Info.plist from your Firebase project.")
            EmbraceService.shared.addSessionProperty(key: "firebase_configured", value: "false")
            EmbraceService.shared.addSessionProperty(key: "firebase_disabled_reason", value: "missing_config_file")
        }
    }
    
    private func configureEmbrace() {
        do {
            // Create basic Embrace configuration  
            let options = Embrace.Options(
                appId: SDKConfiguration.Embrace.appId,
                logLevel: .info
            )
            
            try Embrace
                .setup(options: options)
                .start()
                
            print("✅ Embrace SDK initialized successfully")
            
            // Set initial session properties from configuration
            for (key, value) in SDKConfiguration.Embrace.sessionProperties {
                EmbraceService.shared.addSessionProperty(key: key, value: value, permanent: true)
            }
            EmbraceService.shared.addSessionProperty(key: "third_party_sdks", value: "firebase,mixpanel,stripe,google_signin", permanent: true)
            
        } catch let error {
            print("❌ Error starting Embrace: \(error.localizedDescription)")
            // Still continue app initialization even if Embrace fails
        }
    }
    
    private func configureMixpanel() {
        // Initialize Mixpanel with project token from configuration
        if SDKConfiguration.Mixpanel.isConfigured {
            Mixpanel.initialize(
                token: SDKConfiguration.Mixpanel.projectToken,
                trackAutomaticEvents: SDKConfiguration.Mixpanel.trackAutomaticEvents
            )
            print("✅ Mixpanel configured successfully")
        } else {
            print("⚠️ Mixpanel using placeholder token - replace with actual project token")
            // Initialize with a mock token for development
            Mixpanel.initialize(token: "mock_token_for_testing", trackAutomaticEvents: false)
        }
        
        // Test Mixpanel and Embrace compatibility
        EmbraceService.shared.addSessionProperty(key: "mixpanel_configured", value: "true")
        EmbraceService.shared.logInfo("Mixpanel SDK initialized alongside Embrace")
    }
    
    private func configureGoogleSignIn() {
        // TODO: Replace with your actual Google Sign-In client ID from Google Cloud Console
        // For now, using a placeholder to prevent crashes
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientId = plist["CLIENT_ID"] as? String {
            let config = GIDConfiguration(clientID: clientId)
            GIDSignIn.sharedInstance.configuration = config
        } else {
            // Fallback configuration for testing without Google Services file
            print("⚠️ GoogleService-Info.plist not found. Google Sign-In will use mock mode.")
            // You can add a mock client ID here for testing purposes
            // For testing without a real Google project, use a placeholder
            let testClientId = SDKConfiguration.GoogleSignIn.fallbackClientId
            let config = GIDConfiguration(clientID: testClientId)
            GIDSignIn.sharedInstance.configuration = config
        }
    }
    
    private func configureStripe() {
        // Stripe is initialized automatically when StripePaymentService is first accessed
        // The publishable key is set in StripePaymentService.init()
        print("✅ Stripe configured for test environment")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(CartManager())
                .environmentObject(MockDataService.shared)
                .environmentObject(AuthenticationManager())
                .onOpenURL { url in
                    // Track deep link / URL scheme handling
                    EmbraceService.shared.addBreadcrumb(message: "App opened via URL: \(url.absoluteString)")
                    
                    if url.scheme == "googlesignin" || url.absoluteString.contains("oauth") {
                        // Handle Google Sign-In URL
                        GIDSignIn.sharedInstance.handle(url)
                        EmbraceService.shared.addSessionProperty(key: "launch_source", value: "google_signin_redirect")
                        EmbraceService.shared.logInfo("Google Sign-In URL handled", properties: ["url": url.absoluteString])
                        
                    } else if url.scheme == "embrace-ecommerce" && url.host == "stripe-redirect" {
                        // Handle Stripe redirect URL
                        EmbraceService.shared.addSessionProperty(key: "launch_source", value: "stripe_redirect")
                        EmbraceService.shared.logInfo("Stripe redirect URL handled", properties: ["url": url.absoluteString])
                        print("✅ Stripe redirect URL handled: \(url)")
                        
                    } else {
                        // Handle other deep links
                        EmbraceService.shared.addSessionProperty(key: "launch_source", value: "deeplink")
                        EmbraceService.shared.logInfo("Deep link handled", properties: [
                            "scheme": url.scheme ?? "unknown",
                            "host": url.host ?? "unknown",
                            "url": url.absoluteString
                        ])
                    }
                }
        }
    }
}
