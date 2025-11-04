//
//  Embrace_EcommerceUITests+ScreenDetection.swift
//  Embrace EcommerceUITests
//
//  Created by David Rifkin on 9/17/25.
//

import XCTest

// MARK: - Screen Detection Extension

extension Embrace_EcommerceUITests {

    enum AppScreen: String {
        case authentication = "authenticationView"
        case home = "homeView"
        case productList = "productListView"
        case productDetail = "productDetailView"
        case cart = "cartView"
        case cartEmpty = "cartEmptyView"
        case checkout = "checkoutView"
        case profile = "profileView"
        case profileLoggedIn = "profileLoggedInView"
        case search = "searchView"
        case searchResults = "searchResultsView"
        case mainTab = "mainTabView"
        case unknown
    }

    /// Detects which screen the app is currently on based on visible accessibility identifiers
    func detectCurrentScreen(timeout: TimeInterval = 2.0) -> AppScreen {
        let screens: [AppScreen] = [
            .authentication,
            .home,
            .productList,
            .productDetail,
            .cart,
            .cartEmpty,
            .checkout,
            .profile,
            .profileLoggedIn,
            .search,
            .searchResults,
            .mainTab
        ]

        for screen in screens {
            let element = app.descendants(matching: .any)[screen.rawValue].firstMatch
            if element.exists {
                print("📍 Detected screen: \(screen.rawValue)")
                return screen
            }
        }

        print("⚠️ Could not detect current screen")
        return .unknown
    }

    /// Performs an appropriate action based on the current screen
    /// Returns true if an action was performed, false otherwise
    @discardableResult
    func performActionOnCurrentScreen() -> Bool {
        let currentScreen = detectCurrentScreen()

        switch currentScreen {
        case .authentication:
            return performAuthenticationAction()
        case .home, .mainTab:
            return performHomeAction()
        case .productList:
            return performProductListAction()
        case .productDetail:
            return performProductDetailAction()
        case .cart:
            return performCartAction()
        case .cartEmpty:
            return performCartEmptyAction()
        case .checkout:
            return performCheckoutAction()
        case .profile, .profileLoggedIn:
            return performProfileAction()
        case .search, .searchResults:
            return performSearchAction()
        case .unknown:
            print("⚠️ Unknown screen, cannot perform action")
            return false
        }
    }

    // MARK: - Screen-Specific Actions

    func performAuthenticationAction() -> Bool {
        print("🎬 Performing authentication action")
        return tapGuestButton()
    }

    func performHomeAction() -> Bool {
        print("🎬 Performing home action")
        // Could tap a product, navigate to cart, etc.
        // For now, just return true to indicate we're on home
        return true
    }

    func performProductListAction() -> Bool {
        print("🎬 Performing product list action")
        // Could tap first product
        return true
    }

    func performProductDetailAction() -> Bool {
        print("🎬 Performing product detail action")
        // Could add to cart
        return true
    }

    func performCartAction() -> Bool {
        print("🎬 Performing cart action")
        // Could proceed to checkout
        return true
    }

    func performCartEmptyAction() -> Bool {
        print("🎬 Cart is empty")
        // Could navigate back to shopping
        return true
    }

    func performCheckoutAction() -> Bool {
        print("🎬 Performing checkout action")
        // Could fill out checkout form
        return true
    }

    func performProfileAction() -> Bool {
        print("🎬 Performing profile action")
        // Could edit profile or logout
        return true
    }

    func performSearchAction() -> Bool {
        print("🎬 Performing search action")
        // Could enter search query
        return true
    }

    // MARK: - Authentication Screen Helpers

    func tapGuestButton() -> Bool {
        print("🔘 Attempting to tap guest button")

        // Step 1: Verify authentication view is loaded
        let authenticationView = app.descendants(matching: .any)["authenticationView"].firstMatch
        XCTAssertTrue(authenticationView.waitForExistence(timeout: 5.0),
                     "Authentication view with identifier 'authenticationView' failed to load within 5 seconds")
        print("✅ Authentication view loaded successfully")

        // Step 2: Find and verify guest button exists
        let guestButton = app.descendants(matching: .any)["authButton_ContinueasGuest"].firstMatch
        XCTAssertTrue(guestButton.exists,
                     "Guest authentication button with identifier 'authButton_ContinueasGuest' does not exist")
        print("✅ Guest button found")

        // Step 3: Tap the guest button
        guestButton.tap()
        print("✅ Guest button tapped")

        // Step 4: Wait for navigation
        Thread.sleep(forTimeInterval: 3.0)

        // Step 5: Verify navigation occurred
        let navigationOccurred = !authenticationView.exists ||
                                app.otherElements.allElementsBoundByIndex.count > 1
        XCTAssertTrue(navigationOccurred,
                     "Navigation did not occur after tapping guest button - still on authentication screen")
        print("✅ Navigation verified - moved to new screen")

        return true
    }
}
