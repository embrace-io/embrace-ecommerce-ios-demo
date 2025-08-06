import Foundation
import LocalAuthentication
import EmbraceIO
import OpenTelemetryApi

@MainActor
class BiometricAuthenticationManager: ObservableObject {
    @Published var biometricType: BiometricType = .none
    @Published var isAvailable: Bool = false
    @Published var isEnrolled: Bool = false
    
    private let context = LAContext()
    
    init() {
        checkBiometricAvailability()
    }
    
    // MARK: - Availability Checks
    
    func checkBiometricAvailability() {
        let span = Embrace.client?.buildSpan(
            name: "biometric_availability_check",
            type: .system
        ).startSpan()
        
        var error: NSError?
        let isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        self.isAvailable = isAvailable
        self.biometricType = getBiometricType()
        self.isEnrolled = isAvailable && error == nil
        
        span?.setAttribute(key: "biometric.available", value: String(isAvailable))
        span?.setAttribute(key: "biometric.type", value: biometricType.displayName)
        span?.setAttribute(key: "biometric.enrolled", value: String(isEnrolled))
        
        if let error = error {
            span?.setAttribute(key: "error.code", value: String(error.code))
            span?.setAttribute(key: "error.description", value: error.localizedDescription)
        }
        
        span?.end()
        
        Embrace.client?.log(
            "Biometric availability checked",
            severity: .info,
            attributes: [
                "biometric.available": String(isAvailable),
                "biometric.type": biometricType.displayName,
                "biometric.enrolled": String(isEnrolled)
            ]
        )
    }
    
    private func getBiometricType() -> BiometricType {
        if #available(iOS 17.0, *) {
            switch context.biometryType {
            case .none:
                return .none
            case .touchID:
                return .touchID
            case .faceID:
                return .faceID
            case .opticID:
                return .opticID
            @unknown default:
                return .none
            }
        } else {
            switch context.biometryType {
            case .none:
                return .none
            case .touchID:
                return .touchID
            case .faceID:
                return .faceID
            case .opticID:
                return .opticID
            @unknown default:
                return .none
            }
        }
    }
    
    // MARK: - Authentication
    
    func authenticateWithBiometrics(reason: String = "Authenticate to access your account") async -> Result<Bool, AuthenticationError> {
        let span = Embrace.client?.buildSpan(
            name: "biometric_authentication",
            type: .performance
        ).startSpan()
        
        span?.setAttribute(key: "biometric.type", value: biometricType.displayName)
        span?.setAttribute(key: "authentication.method", value: "biometric")
        
        guard isAvailable else {
            span?.setAttribute(key: "error.type", value: "not_available")
            span?.end()
            
            Embrace.client?.log(
                "Biometric authentication failed - not available",
                severity: .warn,
                attributes: [
                    "biometric.type": biometricType.displayName,
                    "error.type": "not_available"
                ]
            )
            
            return .failure(.biometricNotAvailable)
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            span?.setAttribute(key: "authentication.success", value: String(success))
            span?.end()
            
            Embrace.client?.log(
                "Biometric authentication completed",
                severity: success ? .info : .warn,
                attributes: [
                    "biometric.type": biometricType.displayName,
                    "authentication.success": String(success)
                ]
            )
            
            return .success(success)
            
        } catch let error as LAError {
            let authError = mapLAError(error)
            
            span?.setAttribute(key: "error.code", value: String(error.code.rawValue))
            span?.setAttribute(key: "error.description", value: error.localizedDescription)
            span?.setAttribute(key: "authentication.success", value: "false")
            span?.end()
            
            Embrace.client?.log(
                "Biometric authentication failed",
                severity: .error,
                attributes: [
                    "biometric.type": biometricType.displayName,
                    "error.code": String(error.code.rawValue),
                    "error.description": error.localizedDescription
                ]
            )
            
            return .failure(authError)
            
        } catch {
            span?.setAttribute(key: "error.description", value: error.localizedDescription)
            span?.setAttribute(key: "authentication.success", value: "false")
            span?.end()
            
            Embrace.client?.log(
                "Biometric authentication failed with unknown error",
                severity: .error,
                attributes: [
                    "biometric.type": biometricType.displayName,
                    "error.description": error.localizedDescription
                ]
            )
            
            return .failure(.unknownError(error.localizedDescription))
        }
    }
    
    // MARK: - Mock Biometric for Testing
    
    func mockBiometricAuthentication(shouldSucceed: Bool = true, delay: TimeInterval = 1.0) async -> Result<Bool, AuthenticationError> {
        let span = Embrace.client?.buildSpan(
            name: "mock_biometric_authentication",
            type: .performance
        ).startSpan()
        
        span?.setAttribute(key: "authentication.method", value: "mock_biometric")
        span?.setAttribute(key: "mock.should_succeed", value: String(shouldSucceed))
        span?.setAttribute(key: "mock.delay", value: String(delay))
        
        // Simulate authentication delay
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        if shouldSucceed {
            span?.setAttribute(key: "authentication.success", value: "true")
            span?.end()
            
            Embrace.client?.log(
                "Mock biometric authentication succeeded",
                severity: .info,
                attributes: [
                    "authentication.method": "mock_biometric",
                    "mock.delay": String(delay)
                ]
            )
            
            return .success(true)
        } else {
            span?.setAttribute(key: "authentication.success", value: "false")
            span?.setAttribute(key: "error.type", value: "mock_failure")
            span?.end()
            
            Embrace.client?.log(
                "Mock biometric authentication failed",
                severity: .warn,
                attributes: [
                    "authentication.method": "mock_biometric",
                    "error.type": "mock_failure"
                ]
            )
            
            return .failure(.biometricFailed)
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapLAError(_ error: LAError) -> AuthenticationError {
        switch error.code {
        case .userCancel, .systemCancel, .appCancel:
            return .userCancelled
        case .biometryNotAvailable, .biometryNotEnrolled:
            return .biometricNotAvailable
        case .authenticationFailed:
            return .biometricFailed
        default:
            return .biometricFailed
        }
    }
    
    // MARK: - Settings & Preferences
    
    func enableBiometric(for userId: String) {
        let span = Embrace.client?.buildSpan(
            name: "enable_biometric_auth",
            type: .system
        ).startSpan()
        
        span?.setAttribute(key: "user.id", value: userId)
        span?.setAttribute(key: "biometric.type", value: biometricType.displayName)
        
        UserDefaults.standard.set(true, forKey: "biometric_enabled_\(userId)")
        
        span?.end()
        
        Embrace.client?.log(
            "Biometric authentication enabled",
            severity: .info,
            attributes: [
                "user.id": userId,
                "biometric.type": biometricType.displayName
            ]
        )
    }
    
    func disableBiometric(for userId: String) {
        let span = Embrace.client?.buildSpan(
            name: "disable_biometric_auth",
            type: .system
        ).startSpan()
        
        span?.setAttribute(key: "user.id", value: userId)
        
        UserDefaults.standard.removeObject(forKey: "biometric_enabled_\(userId)")
        
        span?.end()
        
        Embrace.client?.log(
            "Biometric authentication disabled",
            severity: .info,
            attributes: [
                "user.id": userId
            ]
        )
    }
    
    func isBiometricEnabled(for userId: String) -> Bool {
        UserDefaults.standard.bool(forKey: "biometric_enabled_\(userId)")
    }
}

// MARK: - Extensions

extension BiometricAuthenticationManager {
    var statusDescription: String {
        if !isAvailable {
            return "Biometric authentication is not available on this device"
        } else if !isEnrolled {
            return "\(biometricType.displayName) is not set up. Please set it up in Settings"
        } else {
            return "\(biometricType.displayName) is ready to use"
        }
    }
    
    var canUseBiometric: Bool {
        isAvailable && isEnrolled
    }
}
