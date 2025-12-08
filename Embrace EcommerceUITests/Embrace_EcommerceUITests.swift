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
            "RUN_SOURCE": "UITest" // Sends information about how session was run
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
    func testAuthenticationGuestFlow() throws {
        print("Starting authentication guest flow test")

        // Verify we start on the authentication screen
        let currentScreen = detectCurrentScreen()
        XCTAssertEqual(currentScreen, .authentication, "Expected to start on authentication screen")
        print("Verified: Starting on authentication screen")

        // Tap the guest button to continue as guest
        let guestSuccess = tapGuestButton()
        XCTAssertTrue(guestSuccess, "Failed to complete guest authentication")
        print("Completed: Guest authentication flow")

        // Verify we navigated away from authentication
        let newScreen = detectCurrentScreen()
        XCTAssertNotEqual(newScreen, .authentication, "Should have navigated away from authentication screen")
        print("Verified: Navigated to \(newScreen.rawValue)")

        // Send app to background to trigger Embrace session upload
        print("Sending app to background to trigger Embrace session upload...")
        sendAppToBackground()
        print("Background trigger complete")

        // Bring app back to foreground to trigger upload of backgrounded session
        print("Bringing app to foreground to trigger session upload...")
        bringAppToForeground()
        print("Foreground trigger complete")
    }

    @MainActor
    func testBrowseFlow() throws {
        print("Starting browse flow test")

        // Complete authentication first if needed
        let initialScreen = detectCurrentScreen()
        if initialScreen == .authentication {
            let authSuccess = tapGuestButton()
            XCTAssertTrue(authSuccess, "Failed to complete guest authentication")
            print("Completed: Guest authentication")
        }

        // Wait for home view to load
        let homeView = app.descendants(matching: .any)["homeView"].firstMatch
        XCTAssertTrue(homeView.waitForExistence(timeout: 10.0), "Home view did not load")
        print("Verified: Home view loaded")

        // Wait for content to load
        Thread.sleep(forTimeInterval: 2.0)

        // Tap "See All" to navigate to product list
        let seeAllButton = app.descendants(matching: .any)["homeFeaturedProductsSeeAllButton"].firstMatch
        if seeAllButton.waitForExistence(timeout: 5.0) {
            seeAllButton.tap()
            print("Tapped: See All button")
        } else {
            // Fallback: tap on a category if See All not available
            let categoryButton = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'homeCategory_'")).firstMatch
            if categoryButton.waitForExistence(timeout: 5.0) {
                categoryButton.tap()
                print("Tapped: Category button")
            }
        }

        // Wait for product list to load
        Thread.sleep(forTimeInterval: 2.0)

        let productListView = app.descendants(matching: .any)["productListView"].firstMatch
        XCTAssertTrue(productListView.waitForExistence(timeout: 10.0), "Product list view did not load")
        print("Verified: Product list view loaded")

        // Tap on first product to view details
        let productCard = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'homeFeaturedProduct_' OR identifier BEGINSWITH 'homeNewArrival_'")).firstMatch
        if productCard.waitForExistence(timeout: 5.0) {
            productCard.tap()
            print("Tapped: Product card")

            // Wait for product detail to load
            Thread.sleep(forTimeInterval: 2.0)
            print("Viewed: Product detail")
        }

        // Send app to background to trigger Embrace session upload
        print("Sending app to background to trigger Embrace session upload...")
        sendAppToBackground()
        print("Background trigger complete")

        // Bring app back to foreground to trigger upload of backgrounded session
        print("Bringing app to foreground to trigger session upload...")
        bringAppToForeground()
        print("Foreground trigger complete")
    }

    @MainActor
    func testAddToCartFlow() throws {
        print("Starting add to cart flow test")

        // Complete authentication first if needed
        let initialScreen = detectCurrentScreen()
        if initialScreen == .authentication {
            let authSuccess = tapGuestButton()
            XCTAssertTrue(authSuccess, "Failed to complete guest authentication")
            print("Completed: Guest authentication")
        }

        // Wait for home view to load
        let homeView = app.descendants(matching: .any)["homeView"].firstMatch
        XCTAssertTrue(homeView.waitForExistence(timeout: 10.0), "Home view did not load")
        print("Verified: Home view loaded")

        // Wait for content to load
        Thread.sleep(forTimeInterval: 2.0)

        // Tap on a featured product
        let productCard = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'homeFeaturedProduct_'")).firstMatch
        if productCard.waitForExistence(timeout: 5.0) {
            productCard.tap()
            print("Tapped: Featured product")
        } else {
            // Fallback: tap on a new arrival
            let newArrivalCard = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'homeNewArrival_'")).firstMatch
            if newArrivalCard.waitForExistence(timeout: 5.0) {
                newArrivalCard.tap()
                print("Tapped: New arrival product")
            }
        }

        // Wait for product detail to load
        Thread.sleep(forTimeInterval: 2.0)

        // Try to tap Add to Cart button
        let addToCartButton = app.descendants(matching: .any)["productDetailAddToCartButton"].firstMatch
        if addToCartButton.waitForExistence(timeout: 5.0) {
            addToCartButton.tap()
            print("Tapped: Add to Cart button")
            Thread.sleep(forTimeInterval: 1.0)
        }

        // Navigate to cart tab
        let cartTab = app.descendants(matching: .any)["cartTab"].firstMatch
        if cartTab.waitForExistence(timeout: 5.0) {
            cartTab.tap()
            print("Tapped: Cart tab")
        }

        // Wait for cart to load
        Thread.sleep(forTimeInterval: 2.0)

        // Verify we're on cart view
        let cartView = app.descendants(matching: .any)["cartView"].firstMatch
        XCTAssertTrue(cartView.waitForExistence(timeout: 5.0), "Cart view did not load")
        print("Verified: Cart view loaded")

        // Send app to background to trigger Embrace session upload
        print("Sending app to background to trigger Embrace session upload...")
        sendAppToBackground()
        print("Background trigger complete")

        // Bring app back to foreground to trigger upload of backgrounded session
        print("Bringing app to foreground to trigger session upload...")
        bringAppToForeground()
        print("Foreground trigger complete")
    }

    @MainActor
    func testSearchFlow() throws {
        print("Starting search flow test")

        // Complete authentication first if needed
        let initialScreen = detectCurrentScreen()
        if initialScreen == .authentication {
            let authSuccess = tapGuestButton()
            XCTAssertTrue(authSuccess, "Failed to complete guest authentication")
            print("Completed: Guest authentication")
        }

        // Wait for home view to load
        let homeView = app.descendants(matching: .any)["homeView"].firstMatch
        XCTAssertTrue(homeView.waitForExistence(timeout: 15.0), "Home view did not load")
        print("Verified: Home view loaded")

        // Wait for content to fully load
        Thread.sleep(forTimeInterval: 3.0)

        // Navigate to search tab - try multiple approaches
        let searchTab = app.tabBars.buttons["Search"].firstMatch
        if searchTab.waitForExistence(timeout: 10.0) {
            searchTab.tap()
            print("Tapped: Search tab via tab bar")
        } else {
            // Fallback to accessibility identifier
            let searchTabAlt = app.descendants(matching: .any)["searchTab"].firstMatch
            if searchTabAlt.waitForExistence(timeout: 5.0) {
                searchTabAlt.tap()
                print("Tapped: Search tab via identifier")
            }
        }

        // Wait for search view to load
        Thread.sleep(forTimeInterval: 2.0)

        let searchView = app.descendants(matching: .any)["searchView"].firstMatch
        if searchView.waitForExistence(timeout: 10.0) {
            print("Verified: Search view loaded")
        }

        // Tap on a popular category to perform search
        let categoryButton = app.descendants(matching: .any)["categoryButton_Electronics"].firstMatch
        if categoryButton.waitForExistence(timeout: 5.0) {
            categoryButton.tap()
            print("Tapped: Electronics category")
        } else {
            // Try tapping any category button
            let anyCategory = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'categoryButton_'")).firstMatch
            if anyCategory.waitForExistence(timeout: 5.0) {
                anyCategory.tap()
                print("Tapped: Alternative category")
            }
        }

        // Wait for search results
        Thread.sleep(forTimeInterval: 3.0)

        // Verify search results appear (non-fatal if not found)
        let searchResultsView = app.descendants(matching: .any)["searchResultsView"].firstMatch
        if searchResultsView.waitForExistence(timeout: 5.0) {
            print("Verified: Search results loaded")
        } else {
            print("Note: Search results view not found, continuing anyway")
        }

        // Send app to background to trigger Embrace session upload
        print("Sending app to background to trigger Embrace session upload...")
        sendAppToBackground()
        print("Background trigger complete")

        // Bring app back to foreground to trigger upload of backgrounded session
        print("Bringing app to foreground to trigger session upload...")
        bringAppToForeground()
        print("Foreground trigger complete")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
