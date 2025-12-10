//
//  Embrace_EcommerceUITests+CrashSimulation.swift
//  Embrace EcommerceUITests
//
//  Crash simulation logic for testing Embrace crash reporting.
//  Approximately 20% of sessions will experience an intentional crash.
//

import XCTest

// MARK: - Crash Simulation Extension

extension Embrace_EcommerceUITests {

    /// Crash probability threshold (20%)
    /// Values 80-99 trigger a crash (20 out of 100 possible values)
    private static let crashProbabilityThreshold = 79

    /// Calculates whether to trigger a crash based on probability.
    /// Approximately 20% of calls will result in a crash.
    /// Call this at appropriate points in test flows to simulate real-world crash scenarios.
    func calculateAndCreateCrash() {
        let probability = Int.random(in: 0...99)
        print("🎲 Crash probability roll: \(probability) (threshold: >\(Self.crashProbabilityThreshold) to crash)")

        if probability > Self.crashProbabilityThreshold {
            print("💥 Probability check passed - triggering intentional crash")
            tapCrashButton()
        } else {
            print("✅ No crash this session (probability: \(probability))")
        }
    }

    /// Navigates to the Profile tab and taps the crash button.
    /// This triggers `EmbraceService.shared.forceEmbraceCrash()` which
    /// logs an error event and then crashes the app.
    func tapCrashButton() {
        print("💥 Attempting to trigger crash via Profile -> Force Crash button")

        // First, authenticate if needed
        let currentScreen = detectCurrentScreen()
        if currentScreen == .authentication {
            print("📱 Still on authentication screen, completing guest auth first")
            _ = tapGuestButton()
            Thread.sleep(forTimeInterval: 2.0)
        }

        // Navigate to Profile tab
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        if profileTab.waitForExistence(timeout: 5.0) && profileTab.isHittable {
            profileTab.tap()
            print("📱 Navigated to Profile tab")
            Thread.sleep(forTimeInterval: 2.0)
        } else {
            print("⚠️ Could not find Profile tab, crash not triggered")
            return
        }

        // Find and tap the crash button
        let crashButton = app.descendants(matching: .any)["force-crash-button"].firstMatch
        if crashButton.waitForExistence(timeout: 5.0) && crashButton.isHittable {
            print("💥 Tapping crash button - app will crash now")
            crashButton.tap()
            // The app should crash here, so this code won't execute
        } else {
            print("⚠️ Could not find crash button with identifier 'force-crash-button'")
        }
    }

    /// A safer version of crash check that can be called from any test.
    /// This handles the case where we're in a specific flow and need to
    /// potentially crash without disrupting the flow too much.
    ///
    /// - Parameter shouldNavigateToProfile: If true, will navigate to profile to access crash button.
    ///                                      If false, expects we're already on a screen with crash access.
    func maybeCrash(navigateToProfile: Bool = true) {
        let probability = Int.random(in: 0...99)

        if probability > Self.crashProbabilityThreshold {
            print("💥 Crash triggered (roll: \(probability))")
            if navigateToProfile {
                tapCrashButton()
            }
        }
    }
}
