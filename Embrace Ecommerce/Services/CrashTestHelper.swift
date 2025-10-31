//
//  CrashTestHelper.swift
//  Embrace Ecommerce
//
//  Created for Embrace SDK Testing
//

import Foundation
import EmbraceIO

/// Helper utility for intentionally crashing the app in different scenarios
/// Used for testing Embrace crash reporting across multiple simulators and sessions
@MainActor
class CrashTestHelper {

    static let shared = CrashTestHelper()

    private init() {}

    // MARK: - Crash Types

    enum CrashType: String, CaseIterable {
        case forceUnwrap = "Force Unwrap"
        case arrayOutOfBounds = "Array Out of Bounds"
        case divideByZero = "Divide by Zero"
        case invalidMemoryAccess = "Invalid Memory Access"
        case fatalError = "Fatal Error"
        case preconditionFailure = "Precondition Failure"

        var description: String {
            switch self {
            case .forceUnwrap:
                return "Crashes by force unwrapping a nil value"
            case .arrayOutOfBounds:
                return "Crashes by accessing an invalid array index"
            case .divideByZero:
                return "Crashes by dividing by zero"
            case .invalidMemoryAccess:
                return "Crashes by accessing invalid memory"
            case .fatalError:
                return "Crashes using fatalError()"
            case .preconditionFailure:
                return "Crashes using preconditionFailure()"
            }
        }
    }

    // MARK: - Crash Methods

    /// Log crash attempt and trigger the specified crash type
    func triggerCrash(type: CrashType, location: String) {
        logCrashAttempt(type: type, location: location)

        // Small delay to ensure the log is sent to Embrace
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.executeCrash(type: type)
        }
    }

    private func logCrashAttempt(type: CrashType, location: String) {
        // Log to Embrace
        EmbraceService.shared.logInfo("Intentional crash triggered for testing", properties: [
            "crash_type": type.rawValue,
            "crash_location": location,
            "test_purpose": "MCP_server_testing",
            "session_type": "crash_test"
        ])

        // Log to console
        print("🔴 [CRASH TEST] Triggering \(type.rawValue) crash from \(location)")
    }

    private func executeCrash(type: CrashType) {
        switch type {
        case .forceUnwrap:
            crashWithForceUnwrap()
        case .arrayOutOfBounds:
            crashWithArrayOutOfBounds()
        case .divideByZero:
            crashWithDivideByZero()
        case .invalidMemoryAccess:
            crashWithInvalidMemoryAccess()
        case .fatalError:
            crashWithFatalError()
        case .preconditionFailure:
            crashWithPreconditionFailure()
        }
    }

    // MARK: - Specific Crash Implementations

    private func crashWithForceUnwrap() {
        let nilValue: String? = nil
        let _ = nilValue! // This will crash
    }

    private func crashWithArrayOutOfBounds() {
        let array = [1, 2, 3]
        let _ = array[10] // This will crash
    }

    private func crashWithDivideByZero() {
        let numbers = [5, 3, 2, 1, 0]
        let divisor = numbers.last! // This gets 0 dynamically
        let _ = 100 / divisor // This will crash
    }

    private func crashWithInvalidMemoryAccess() {
        let pointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        pointer.deallocate()
        pointer.pointee = 42 // This will crash - accessing deallocated memory
    }

    private func crashWithFatalError() {
        fatalError("Test crash: Fatal error triggered for Embrace SDK testing")
    }

    private func crashWithPreconditionFailure() {
        preconditionFailure("Test crash: Precondition failure for Embrace SDK testing")
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

/// A view modifier that adds a crash test button to any view
struct CrashTestButton: ViewModifier {
    let location: String
    @State private var showingCrashOptions = false

    func body(content: Content) -> some View {
        ZStack(alignment: .bottomTrailing) {
            content

            Button(action: {
                showingCrashOptions = true
            }) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.red)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(16)
            .confirmationDialog(
                "Test Crash",
                isPresented: $showingCrashOptions,
                titleVisibility: .visible
            ) {
                ForEach(CrashTestHelper.CrashType.allCases, id: \.self) { crashType in
                    Button(crashType.rawValue, role: .destructive) {
                        CrashTestHelper.shared.triggerCrash(
                            type: crashType,
                            location: location
                        )
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Select a crash type to test Embrace crash reporting.\n\n⚠️ This will crash the app!")
            }
        }
    }
}

extension View {
    /// Adds a crash test button to the view for testing purposes
    /// - Parameter location: A string identifying the current view/screen
    func crashTestButton(location: String) -> some View {
        modifier(CrashTestButton(location: location))
    }
}
