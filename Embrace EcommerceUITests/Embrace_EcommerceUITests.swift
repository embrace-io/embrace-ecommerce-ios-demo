//
//  Embrace_EcommerceUITests.swift
//  Embrace EcommerceUITests
//
//  Created by David Rifkin on 9/17/25.
//

import XCTest

final class Embrace_EcommerceUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Configure the app with launch environment variables
        app = XCUIApplication()
        app.launchEnvironment = [
            "UI_TESTING": "1", // NOT IN USE.
            "DISABLE_NETWORK_CALLS": "1", // NOT IN USE. Disable app network calls but allow Embrace SDK
            "USE_MOCK_DATA": "1", // NOT IN USE.
            "ALLOW_EMBRACE_NETWORK": "1", // NOT IN USE. Allow Embrace SDK network requests
            "RUN_SOURCE": runSource // Sends information about how session was run
        ]
        app.launch()

        // Wait for Embrace SDK to fully initialize
        Thread.sleep(forTimeInterval: 3.0)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testFlow() throws {
        print("🧪 Starting adaptive test flow")

        // Detect current screen and perform appropriate action
        let currentScreen = detectCurrentScreen()
        print("📍 Current screen: \(currentScreen)")

        // Perform action based on detected screen
        let actionPerformed = performActionOnCurrentScreen()
        XCTAssertTrue(actionPerformed, "Failed to perform action on screen: \(currentScreen)")

        // Send app to background to trigger Embrace session upload
        print("📤 Sending app to background to trigger Embrace session upload...")
        sendAppToBackground()
        print("✅ Background trigger complete")

        // Bring app back to foreground to trigger upload of backgrounded session
        print("📤 Bringing app to foreground to trigger session upload...")
        bringAppToForeground()
        print("✅ Foreground trigger complete")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
