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

@main
struct Embrace_EcommerceApp: App {
    init() {
        // Initialize Embrace SDK
        do {
            try Embrace
                .setup(
                    options: Embrace.Options(
                        appId: "YOUR_APP_ID", // TODO: Replace with actual App ID from Embrace Dashboard
                        logLevel: .default
                    )
                )
                .start()
        } catch let e {
            print("Error starting Embrace: \(e.localizedDescription)")
        }
        
        // Configure Google Sign-In
        configureGoogleSignIn()
        
        // Initialize Stripe
        configureStripe()
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
            let testClientId = "123456789-abcdefg.apps.googleusercontent.com"
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
                    // Handle Google Sign-In URL
                    GIDSignIn.sharedInstance.handle(url)
                    
                    // Handle Stripe redirect URL
                    if url.scheme == "embrace-ecommerce" && url.host == "stripe-redirect" {
                        // Stripe will handle this automatically
                        print("✅ Stripe redirect URL handled: \(url)")
                    }
                }
        }
    }
}
