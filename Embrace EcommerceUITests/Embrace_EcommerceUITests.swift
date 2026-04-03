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
        // Write sentinel file for cart prefill (reliable on cloned simulators
        // where launchEnvironment/launchArguments may not reach the app)
        FileManager.default.createFile(atPath: "/tmp/ui_test_prefill_cart", contents: nil)

        app = XCUIApplication()
        app.launchArguments += ["-PREFILL_CART", "1"]
        app.launchEnvironment = [
            "UI_TESTING": "1",
            "PREFILL_CART": "1",
            "RUN_SOURCE": "UITest"
        ]
        app.launch()

        // Wait for Embrace SDK to fully initialize and send any
        // previous crash session data from a prior run
        Thread.sleep(forTimeInterval: 10.0)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(atPath: "/tmp/ui_test_prefill_cart")
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

        // ~20% chance to crash the app to demonstrate Embrace crash reporting
        calculateAndCreateCrash()

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

        // Tap a category to reach product list (proven to work in testBrowseFlow)
        Thread.sleep(forTimeInterval: 2.0)
        let categoryButton = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'homeCategory_'")).firstMatch
        if categoryButton.waitForExistence(timeout: 10.0) {
            categoryButton.tap()
            print("Tapped: Category button")
        }
        Thread.sleep(forTimeInterval: 3.0)

        // Tap first product from the product list
        let productRow = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'productListRow_'")).firstMatch
        if productRow.waitForExistence(timeout: 10.0) {
            productRow.tap()
            print("Tapped: Product from list")
        }

        // Wait for product detail to load
        Thread.sleep(forTimeInterval: 3.0)

        // Try to tap Add to Cart button
        let addToCartButton = app.descendants(matching: .any)["productDetailAddToCartButton"].firstMatch
        if addToCartButton.waitForExistence(timeout: 10.0) {
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

        // ~35% chance to crash the app to demonstrate Embrace crash reporting
        calculateAndCreateCrash()

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

        // Wait for app to stabilize
        Thread.sleep(forTimeInterval: 5.0)

        // Try to navigate to search tab using multiple methods
        var searchTabFound = false

        // Method 1: Tab bar button by label
        let searchTabBar = app.tabBars.buttons["Search"].firstMatch
        if searchTabBar.waitForExistence(timeout: 5.0) && searchTabBar.isHittable {
            searchTabBar.tap()
            searchTabFound = true
            print("Tapped: Search tab via tab bar")
        }

        // Method 2: Accessibility identifier
        if !searchTabFound {
            let searchTabId = app.descendants(matching: .any)["searchTab"].firstMatch
            if searchTabId.waitForExistence(timeout: 5.0) && searchTabId.isHittable {
                searchTabId.tap()
                searchTabFound = true
                print("Tapped: Search tab via identifier")
            }
        }

        // Method 3: Any tab with magnifying glass
        if !searchTabFound {
            let anySearchTab = app.tabBars.buttons.element(boundBy: 1)
            if anySearchTab.waitForExistence(timeout: 5.0) && anySearchTab.isHittable {
                anySearchTab.tap()
                searchTabFound = true
                print("Tapped: Search tab via index")
            }
        }

        // Wait for navigation
        Thread.sleep(forTimeInterval: 3.0)

        // Try to interact with search - tap a category if available
        let categoryButton = app.buttons["categoryButton_Electronics"].firstMatch
        if categoryButton.waitForExistence(timeout: 5.0) && categoryButton.isHittable {
            categoryButton.tap()
            print("Tapped: Electronics category")
            Thread.sleep(forTimeInterval: 2.0)
        }

        // ~20% chance to crash the app to demonstrate Embrace crash reporting
        calculateAndCreateCrash()

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
    func testMultiSessionTimeline() throws {
        // This test creates multiple sessions within 5 minutes to demonstrate
        // Embrace's session timeline stitching feature
        print("Starting multi-session timeline test")

        // SESSION 1: Authentication
        let initialScreen = detectCurrentScreen()
        if initialScreen == .authentication {
            let authSuccess = tapGuestButton()
            XCTAssertTrue(authSuccess, "Failed to complete guest authentication")
            print("Session 1: Completed guest authentication")
        }

        Thread.sleep(forTimeInterval: 3.0)
        print("Session 1: Ending - going to background")
        sendAppToBackground()
        Thread.sleep(forTimeInterval: 2.0)

        // SESSION 2: Browse products
        print("Session 2: Starting - coming to foreground")
        bringAppToForeground()
        Thread.sleep(forTimeInterval: 2.0)

        // Navigate to a product
        let productCard = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'homeFeaturedProduct_'")).firstMatch
        if productCard.waitForExistence(timeout: 5.0) && productCard.isHittable {
            productCard.tap()
            print("Session 2: Tapped featured product")
            Thread.sleep(forTimeInterval: 2.0)
        }

        print("Session 2: Ending - going to background")
        sendAppToBackground()
        Thread.sleep(forTimeInterval: 2.0)

        // SESSION 3: View cart
        print("Session 3: Starting - coming to foreground")
        bringAppToForeground()
        Thread.sleep(forTimeInterval: 2.0)

        // Navigate to cart tab
        let cartTab = app.tabBars.buttons["Cart"].firstMatch
        if cartTab.waitForExistence(timeout: 5.0) && cartTab.isHittable {
            cartTab.tap()
            print("Session 3: Navigated to cart")
            Thread.sleep(forTimeInterval: 2.0)
        }

        // ~20% chance to crash during session 3 to demonstrate crash in stitched timeline
        calculateAndCreateCrash()

        print("Session 3: Ending - going to background")
        sendAppToBackground()
        Thread.sleep(forTimeInterval: 2.0)

        // SESSION 4: Search
        print("Session 4: Starting - coming to foreground")
        bringAppToForeground()
        Thread.sleep(forTimeInterval: 2.0)

        // Navigate to search tab
        let searchTab = app.tabBars.buttons["Search"].firstMatch
        if searchTab.waitForExistence(timeout: 5.0) && searchTab.isHittable {
            searchTab.tap()
            print("Session 4: Navigated to search")
            Thread.sleep(forTimeInterval: 2.0)
        }

        print("Session 4: Ending - going to background")
        sendAppToBackground()
        Thread.sleep(forTimeInterval: 2.0)

        // SESSION 5: Profile
        print("Session 5: Starting - coming to foreground")
        bringAppToForeground()
        Thread.sleep(forTimeInterval: 2.0)

        // Navigate to profile tab
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        if profileTab.waitForExistence(timeout: 5.0) && profileTab.isHittable {
            profileTab.tap()
            print("Session 5: Navigated to profile")
            Thread.sleep(forTimeInterval: 2.0)
        }

        // Final background to end all sessions
        print("Session 5: Ending - final background")
        sendAppToBackground()
        Thread.sleep(forTimeInterval: 3.0)

        // Bring back to foreground to trigger upload of all sessions
        print("Bringing to foreground to trigger session uploads")
        bringAppToForeground()
        Thread.sleep(forTimeInterval: 2.0)

        print("Multi-session timeline test complete - should see 5+ sessions stitched together")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Additional Test Variations for Session Diversity
    // These tests create different user journeys to generate diverse sessions
    // similar to Android's CheckoutFlowTestsSuccess, CheckoutFlowTestsFailure, etc.

    @MainActor
    func testQuickBrowseAndLeave() throws {
        // Simulates a user who quickly browses and leaves
        // Creates a short session with minimal interaction
        print("Starting quick browse and leave test")

        // Complete authentication first if needed
        let initialScreen = detectCurrentScreen()
        if initialScreen == .authentication {
            let authSuccess = tapGuestButton()
            XCTAssertTrue(authSuccess, "Failed to complete guest authentication")
        }

        // Wait for home view
        let homeView = app.descendants(matching: .any)["homeView"].firstMatch
        XCTAssertTrue(homeView.waitForExistence(timeout: 10.0), "Home view did not load")

        // Brief pause to simulate looking at home screen
        Thread.sleep(forTimeInterval: 2.0)

        // Send app to background (user leaves quickly)
        print("User leaving quickly - going to background")
        sendAppToBackground()

        // Bring back to trigger session upload
        bringAppToForeground()
        print("Quick browse and leave test complete")
    }

    @MainActor
    func testAbandonedCartFlow() throws {
        // Simulates a user who adds to cart but abandons checkout
        // Similar to Android's full_checkout_abandoned test
        print("Starting abandoned cart flow test")

        // Complete authentication first if needed
        let initialScreen = detectCurrentScreen()
        if initialScreen == .authentication {
            let authSuccess = tapGuestButton()
            XCTAssertTrue(authSuccess, "Failed to complete guest authentication")
        }

        // Wait for home view
        Thread.sleep(forTimeInterval: 3.0)

        // Tap on any available product
        let productCard = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'homeFeaturedProduct_' OR identifier BEGINSWITH 'homeNewArrival_'")).firstMatch
        if productCard.waitForExistence(timeout: 10.0) && productCard.isHittable {
            productCard.tap()
            print("Tapped: Product card")
            Thread.sleep(forTimeInterval: 3.0)
        }

        // Add to cart
        let addToCartButton = app.descendants(matching: .any)["productDetailAddToCartButton"].firstMatch
        if addToCartButton.waitForExistence(timeout: 10.0) && addToCartButton.isHittable {
            addToCartButton.tap()
            print("Tapped: Add to Cart")
            Thread.sleep(forTimeInterval: 2.0)
        }

        // Navigate to cart
        let cartTab = app.tabBars.buttons["Cart"].firstMatch
        if cartTab.waitForExistence(timeout: 5.0) && cartTab.isHittable {
            cartTab.tap()
            print("Navigated to cart")
            Thread.sleep(forTimeInterval: 2.0)
        }

        // ~20% chance to crash during abandoned cart flow
        calculateAndCreateCrash()

        // User abandons - goes to background without completing checkout
        print("User abandoning cart - going to background")
        sendAppToBackground()

        // Bring back to trigger session upload
        bringAppToForeground()
        print("Abandoned cart flow test complete")
    }

    @MainActor
    func testProfileViewFlow() throws {
        // Simulates a user who views their profile
        print("Starting profile view flow test")

        // Complete authentication first if needed
        let initialScreen = detectCurrentScreen()
        if initialScreen == .authentication {
            let authSuccess = tapGuestButton()
            XCTAssertTrue(authSuccess, "Failed to complete guest authentication")
        }

        Thread.sleep(forTimeInterval: 3.0)

        // Navigate to profile tab
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        if profileTab.waitForExistence(timeout: 5.0) && profileTab.isHittable {
            profileTab.tap()
            print("Navigated to profile")
            Thread.sleep(forTimeInterval: 3.0)
        }

        // Interact with profile elements if available
        let profileView = app.descendants(matching: .any)["profileView"].firstMatch
        if profileView.waitForExistence(timeout: 5.0) {
            print("Profile view loaded")
            Thread.sleep(forTimeInterval: 2.0)
        }

        // Send app to background
        print("Ending profile session - going to background")
        sendAppToBackground()

        // Bring back to trigger session upload
        bringAppToForeground()
        print("Profile view flow test complete")
    }

    @MainActor
    func testRepeatProductBrowsing() throws {
        // Simulates a user browsing multiple products
        // Creates activity similar to Android's checkout tests with multiple interactions
        print("Starting repeat product browsing test")

        // Complete authentication first if needed
        let initialScreen = detectCurrentScreen()
        if initialScreen == .authentication {
            let authSuccess = tapGuestButton()
            XCTAssertTrue(authSuccess, "Failed to complete guest authentication")
        }

        Thread.sleep(forTimeInterval: 3.0)

        // Browse first product
        let productCards = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'homeFeaturedProduct_'"))
        if productCards.count > 0 {
            let firstProduct = productCards.element(boundBy: 0)
            if firstProduct.waitForExistence(timeout: 5.0) && firstProduct.isHittable {
                firstProduct.tap()
                print("Viewing product 1")
                Thread.sleep(forTimeInterval: 2.0)

                // Go back to home
                let backButton = app.navigationBars.buttons.element(boundBy: 0)
                if backButton.exists && backButton.isHittable {
                    backButton.tap()
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
        }

        // Browse new arrivals section if available
        let newArrivals = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'homeNewArrival_'"))
        if newArrivals.count > 0 {
            let arrival = newArrivals.element(boundBy: 0)
            if arrival.waitForExistence(timeout: 5.0) && arrival.isHittable {
                arrival.tap()
                print("Viewing new arrival")
                Thread.sleep(forTimeInterval: 2.0)
            }
        }

        // ~20% chance to crash during repeat browsing
        calculateAndCreateCrash()

        // Send app to background
        print("Ending browsing session - going to background")
        sendAppToBackground()

        // Bring back to trigger session upload
        bringAppToForeground()
        print("Repeat product browsing test complete")
    }

    @MainActor
    func testCheckoutFlow() throws {
        // Exercises the full checkout flow to trigger all 4 user journey breadcrumbs:
        // CHECKOUT_STARTED → CHECKOUT_SHIPPING_COMPLETED → CHECKOUT_PAYMENT_COMPLETED
        // → PLACE_ORDER_INITIATED → ORDER_PLACED_SUCCESS
        //
        // This test uses continueAfterFailure = true so that even if a step fails,
        // the test keeps going and fires as many breadcrumbs as possible for User Flows.
        continueAfterFailure = true
        print("Starting checkout flow test")

        // Cart is pre-filled from setUp via -PREFILL_CART launch argument

        // Step 1: Authenticate as guest if needed
        let initialScreen = detectCurrentScreen()
        if initialScreen == .authentication {
            let authSuccess = tapGuestButton()
            guard authSuccess else {
                XCTFail("Failed to complete guest authentication")
                return
            }
            print("Completed: Guest authentication")
        }
        Thread.sleep(forTimeInterval: 3.0)

        // Step 2: Navigate to cart tab
        let cartTab = app.descendants(matching: .any)["cartTab"].firstMatch
        if cartTab.waitForExistence(timeout: 5.0) {
            cartTab.tap()
        } else {
            let cartTabBar = app.tabBars.buttons["Cart"].firstMatch
            if cartTabBar.waitForExistence(timeout: 5.0) {
                cartTabBar.tap()
            }
        }
        print("Navigated to cart")
        Thread.sleep(forTimeInterval: 2.0)

        // Step 5: Tap "Proceed to Checkout" → triggers CHECKOUT_STARTED
        Thread.sleep(forTimeInterval: 2.0)
        // Use staticTexts to find and tap the actual text element inside the button
        // (SwiftUI parent accessibilityIdentifiers override child button identifiers)
        let proceedButton = app.buttons.matching(NSPredicate(format: "label == 'Proceed to Checkout'")).firstMatch
        guard proceedButton.waitForExistence(timeout: 10.0) else {
            XCTFail("Proceed to Checkout button not found - cart may be empty")
            sendAppToBackground()
            bringAppToForeground()
            return
        }
        // Use identifier + coordinate tap to trigger the actual SwiftUI button action
        let proceedById = app.descendants(matching: .any)["cartProceedToCheckoutButton"].firstMatch
        if proceedById.exists {
            proceedById.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        } else {
            proceedButton.tap()
        }
        print("Tapped: Proceed to Checkout (CHECKOUT_STARTED)")

        // Steps 6-12: All taps use coordinate(withNormalizedOffset:) to bypass
        // SwiftUI parent accessibilityIdentifier propagation that prevents normal tap()

        // Step 6: Cart Review → "Continue to Shipping" (SwiftUI button with HStack)
        let continueToShipping = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Continue to Shipping'")).firstMatch
        if continueToShipping.waitForExistence(timeout: 10.0) {
            continueToShipping.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            print("Tapped: Continue to Shipping")
        } else {
            print("WARNING: Continue to Shipping not found")
        }
        Thread.sleep(forTimeInterval: 2.0)

        // Step 7: Shipping → select an address (UIKit button)
        let selectAddressButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Select Address'")).firstMatch
        if selectAddressButton.waitForExistence(timeout: 10.0) {
            selectAddressButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            print("Tapped: Select Address")
            Thread.sleep(forTimeInterval: 1.0)
        } else {
            print("WARNING: Select Address not found")
        }

        // Step 8: Shipping → select a shipping method (UIKit view with tap gesture)
        let shippingMethod = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] 'Standard Shipping'")).firstMatch
        if shippingMethod.waitForExistence(timeout: 10.0) {
            shippingMethod.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            print("Tapped: Standard Shipping method")
            Thread.sleep(forTimeInterval: 1.0)
        } else {
            print("WARNING: Shipping method not found")
        }

        // Step 9: "Continue to Payment" → triggers CHECKOUT_SHIPPING_COMPLETED (UIKit button)
        let continueToPayment = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Continue to Payment'")).firstMatch
        if continueToPayment.waitForExistence(timeout: 10.0) {
            continueToPayment.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            print("Tapped: Continue to Payment")
        } else {
            print("WARNING: Continue to Payment not found")
        }
        Thread.sleep(forTimeInterval: 2.0)

        // Step 10: Select PayPal as payment method (enables "Review Order" button)
        let paypal = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] 'PayPal'")).firstMatch
        if paypal.waitForExistence(timeout: 10.0) {
            paypal.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            print("Tapped: PayPal")
        } else {
            print("WARNING: PayPal not found")
        }
        Thread.sleep(forTimeInterval: 1.0)

        // Step 11: "Review Order" → triggers CHECKOUT_PAYMENT_COMPLETED (SwiftUI button with HStack)
        let reviewOrder = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Review Order'")).firstMatch
        if reviewOrder.waitForExistence(timeout: 10.0) {
            reviewOrder.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            print("Tapped: Review Order")
        } else {
            print("WARNING: Review Order not found")
        }
        Thread.sleep(forTimeInterval: 2.0)

        // Step 11: "Place Order" → triggers PLACE_ORDER_INITIATED + ORDER_PLACED_SUCCESS (UIKit button)
        let placeOrderButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Place Order'")).firstMatch
        if placeOrderButton.waitForExistence(timeout: 10.0) {
            placeOrderButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            print("Tapped: Place Order")
        } else {
            print("WARNING: Place Order not found")
        }
        Thread.sleep(forTimeInterval: 3.0)

        // Step 12: Dismiss the success alert
        let continueShoppingButton = app.alerts.buttons["Continue Shopping"].firstMatch
        if continueShoppingButton.waitForExistence(timeout: 5.0) {
            continueShoppingButton.tap()
            print("Tapped: Continue Shopping")
        }
        Thread.sleep(forTimeInterval: 2.0)

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
    func testHomeToSearchToCartFlow() throws {
        // Simulates a comprehensive user journey through multiple app areas
        // Creates rich session data with many screen transitions
        print("Starting home-search-cart flow test")

        // Complete authentication first if needed
        let initialScreen = detectCurrentScreen()
        if initialScreen == .authentication {
            let authSuccess = tapGuestButton()
            XCTAssertTrue(authSuccess, "Failed to complete guest authentication")
        }

        Thread.sleep(forTimeInterval: 3.0)

        // Step 1: Browse home
        print("Step 1: Viewing home screen")
        Thread.sleep(forTimeInterval: 2.0)

        // Step 2: Go to search
        let searchTab = app.tabBars.buttons["Search"].firstMatch
        if searchTab.waitForExistence(timeout: 5.0) && searchTab.isHittable {
            searchTab.tap()
            print("Step 2: Navigated to search")
            Thread.sleep(forTimeInterval: 2.0)
        }

        // Step 3: Interact with search/categories if available
        let categoryButton = app.buttons["categoryButton_Electronics"].firstMatch
        if categoryButton.waitForExistence(timeout: 3.0) && categoryButton.isHittable {
            categoryButton.tap()
            print("Step 3: Selected category")
            Thread.sleep(forTimeInterval: 2.0)
        }

        // Step 4: Go to cart
        let cartTab = app.tabBars.buttons["Cart"].firstMatch
        if cartTab.waitForExistence(timeout: 5.0) && cartTab.isHittable {
            cartTab.tap()
            print("Step 4: Navigated to cart")
            Thread.sleep(forTimeInterval: 2.0)
        }

        // Step 5: Back to home
        let homeTab = app.tabBars.buttons["Home"].firstMatch
        if homeTab.waitForExistence(timeout: 5.0) && homeTab.isHittable {
            homeTab.tap()
            print("Step 5: Back to home")
            Thread.sleep(forTimeInterval: 2.0)
        }

        // ~20% chance to crash during comprehensive flow
        calculateAndCreateCrash()

        // Send app to background
        print("Ending comprehensive flow - going to background")
        sendAppToBackground()

        // Bring back to trigger session upload
        bringAppToForeground()
        print("Home-search-cart flow test complete")
    }
}
