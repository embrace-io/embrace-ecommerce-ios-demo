//
//  Embrace_EcommerceUITests+BackgroundForeground.swift
//  Embrace EcommerceUITests
//
//  Created by David Rifkin on 9/17/25.
//

import XCTest

// MARK: - Background/Foreground Extension

extension Embrace_EcommerceUITests {

    /// Sends the app to background to trigger Embrace session uploads
    func sendAppToBackground() {
        // Send app to background by opening Settings app
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.launch()
        // Wait for the app state to transition
        Thread.sleep(forTimeInterval: 1.0)

        // Verify that Settings is in the foreground and Ecommerce is in background
        _ = settings.wait(for: .runningForeground, timeout: 5.0)

        XCTAssertEqual(settings.state, .runningForeground,
                       "Settings app should be in foreground")
        print("✅ Verified: Settings app in foreground, Embrace Ecommerce in background")

        // Wait to allow Embrace SDK time to upload sessions
        Thread.sleep(forTimeInterval: 10.0)
    }

    /// Sends the app to foreground to trigger Embrace session uploads for background session
    func bringAppToForeground() {
        // Bring app to foreground
        app.activate()

        // Wait for the app state to transition
        Thread.sleep(forTimeInterval: 1.0)

        // Verify that Embrace Ecommerce is in the foreground and Ecommerce is in background
        _ = app.wait(for: .runningForeground, timeout: 5.0)

        XCTAssertEqual(app.state, .runningForeground,
                       "Embrace Ecommerce app should be in foreground")
        print("✅ Verified: Embrace Ecommerce app in foreground")

        // Wait to allow Embrace SDK time to upload background sessions
        Thread.sleep(forTimeInterval: 10.0)
    }
}
