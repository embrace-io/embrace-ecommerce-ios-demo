import Foundation
import Combine
import EmbraceIO
import GoogleSignIn
import GoogleSignInSwift
import OpenTelemetryApi

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var authState: AuthenticationState = .unauthenticated
    @Published var isLoading: Bool = false
    @Published var currentUser: AuthenticatedUser?
    
    private let biometricManager = BiometricAuthenticationManager()
    private var cancellables = Set<AnyCancellable>()
    private let mockDataService = MockDataService.shared
    private let analytics = MixpanelAnalyticsService.shared
    private let embraceService = EmbraceService.shared
    
    // Mock authentication configuration
    private let mockAuthConfig = MockAuthConfiguration()
    
    init() {
        _ = loadSavedUser()
        setupBindings()
    }
    
    // MARK: - Setup and Bindings
    
    private func setupBindings() {
        // Listen to auth state changes
        $authState
            .sink { [weak self] state in
                if case .authenticated(let user) = state {
                    self?.currentUser = user
                } else {
                    self?.currentUser = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Email Authentication (Mock)
    
    func signInWithEmail(email: String, password: String) async {
        let span = Embrace.client?.buildSpan(
            name: "email_sign_in",
            type: .performance
        ).startSpan()

        await MainActor.run {
            isLoading = true
            authState = .authenticating
        }

        // Login Flow Start: USER_LOGIN_STARTED breadcrumb
        embraceService.addBreadcrumb(message: "USER_LOGIN_STARTED_EMAIL")
        
        span?.setAttribute(key: "auth.method", value: "email")
        span?.setAttribute(key: "auth.email", value: email)
        span?.setAttribute(key: "auth.provider", value: "mock")
        
        do {
            // Simulate network delay
            let delay = mockAuthConfig.getRandomDelay()
            span?.setAttribute(key: "mock.delay", value: String(delay))
            
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Mock authentication logic
            let authResult = mockEmailAuthentication(email: email, password: password)
            
            if authResult.success {
                let user = AuthenticatedUser(
                    id: UUID().uuidString,
                    email: email,
                    displayName: extractDisplayName(from: email),
                    photoURL: nil,
                    authMethod: .email,
                    createdAt: Date(),
                    lastSignInAt: Date(),
                    isGuest: false,
                    biometricEnabled: false
                )
                
                analytics.trackUserSignIn(method: "email", success: true)

                // Login Flow Success: USER_LOGIN_SUCCESS breadcrumb
                embraceService.addBreadcrumb(message: "USER_LOGIN_SUCCESS_EMAIL")

                await handleSuccessfulAuthentication(user: user, span: span)
                
            } else {
                analytics.trackUserSignIn(method: "email", success: false)

                // Login Flow Failure: USER_LOGIN_FAILED breadcrumb
                embraceService.addBreadcrumb(message: "USER_LOGIN_FAILED_EMAIL")

                await handleAuthenticationError(.invalidCredentials, span: span)
            }
            
        } catch {
            await handleAuthenticationError(.networkError, span: span)
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func registerWithEmail(email: String, password: String, displayName: String) async {
        let span = Embrace.client?.buildSpan(
            name: "email_registration",
            type: .performance
        ).startSpan()
        
        await MainActor.run {
            isLoading = true
            authState = .authenticating
        }
        
        span?.setAttribute(key: "auth.method", value: "email_registration")
        span?.setAttribute(key: "auth.email", value: email)
        span?.setAttribute(key: "auth.display_name", value: displayName)
        span?.setAttribute(key: "auth.provider", value: "mock")
        
        do {
            // Simulate network delay
            let delay = mockAuthConfig.getRandomDelay()
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Mock registration - always succeeds for now
            let user = AuthenticatedUser(
                id: UUID().uuidString,
                email: email,
                displayName: displayName,
                photoURL: nil,
                authMethod: .email,
                createdAt: Date(),
                lastSignInAt: Date(),
                isGuest: false,
                biometricEnabled: false
            )
            
            analytics.trackUserSignUp(method: "email", success: true)
            await handleSuccessfulAuthentication(user: user, span: span)
            
        } catch {
            await handleAuthenticationError(.networkError, span: span)
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Google Sign-In
    
    func restorePreviousGoogleSignIn() async {
        // This will be called automatically by the app, but we can also expose it
        // for manual restoration if needed
        await MainActor.run {
            isLoading = true
        }
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            Task { @MainActor in
                if let user = user {
                    let authenticatedUser = AuthenticatedUser(
                        id: user.userID ?? UUID().uuidString,
                        email: user.profile?.email ?? "",
                        displayName: user.profile?.name ?? "Google User",
                        photoURL: user.profile?.imageURL(withDimension: 128)?.absoluteString,
                        authMethod: .google,
                        createdAt: Date(),
                        lastSignInAt: Date(),
                        isGuest: false,
                        biometricEnabled: false
                    )
                    
                    self?.authState = .authenticated(authenticatedUser)
                    self?.currentUser = authenticatedUser
                    self?.saveUser(authenticatedUser)
                    
                    Embrace.client?.log(
                        "Google Sign-In restored from previous session",
                        severity: .info,
                        attributes: [
                            "user.id": user.userID ?? "unknown",
                            "user.email": user.profile?.email ?? "unknown"
                        ]
                    )
                }
                self?.isLoading = false
            }
        }
    }
    
    func signInWithGoogle() async {
        let span = Embrace.client?.buildSpan(
            name: "google_sign_in",
            type: .performance
        ).startSpan()
        
        await MainActor.run {
            isLoading = true
            authState = .authenticating
        }

        // Login Flow Start: USER_LOGIN_STARTED breadcrumb
        embraceService.addBreadcrumb(message: "USER_LOGIN_STARTED_GOOGLE")

        span?.setAttribute(key: "auth.method", value: "google")
        span?.setAttribute(key: "auth.provider", value: "google")
        
        guard let presentingViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else {
            await handleAuthenticationError(.unknownError("No presenting view controller"), span: span)
            await MainActor.run { isLoading = false }
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let user = result.user
            
            span?.setAttribute(key: "google.user_id", value: user.userID ?? "unknown")
            span?.setAttribute(key: "google.email", value: user.profile?.email ?? "unknown")
            
            let authenticatedUser = AuthenticatedUser(
                id: user.userID ?? UUID().uuidString,
                email: user.profile?.email ?? "",
                displayName: user.profile?.name ?? "Google User",
                photoURL: user.profile?.imageURL(withDimension: 128)?.absoluteString,
                authMethod: .google,
                createdAt: Date(),
                lastSignInAt: Date(),
                isGuest: false,
                biometricEnabled: false
            )
            
            analytics.trackUserSignIn(method: "google", success: true)

            // Login Flow Success: USER_LOGIN_SUCCESS breadcrumb
            embraceService.addBreadcrumb(message: "USER_LOGIN_SUCCESS_GOOGLE")

            await handleSuccessfulAuthentication(user: authenticatedUser, span: span)
            
        } catch {
            span?.setAttribute(key: "error.description", value: error.localizedDescription)
            analytics.trackUserSignIn(method: "google", success: false)

            // Login Flow Failure: USER_LOGIN_FAILED breadcrumb
            embraceService.addBreadcrumb(message: "USER_LOGIN_FAILED_GOOGLE")

            await handleAuthenticationError(.googleSignInFailed(error.localizedDescription), span: span)
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Guest Authentication
    
    func continueAsGuest() async {
        let span = Embrace.client?.buildSpan(
            name: "guest_sign_in",
            type: .performance
        ).startSpan()
        
        await MainActor.run {
            isLoading = true
            authState = .authenticating
        }
        
        span?.setAttribute(key: "auth.method", value: "guest")
        span?.setAttribute(key: "auth.provider", value: "mock")

        // Login Flow Start: USER_LOGIN_STARTED breadcrumb
        embraceService.addBreadcrumb(message: "USER_LOGIN_STARTED_GUEST")

        // Simulate brief delay for consistency
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        let guestUser = AuthenticatedUser(
            id: "guest_\(UUID().uuidString)",
            email: "guest@example.com",
            displayName: "Guest User",
            photoURL: nil,
            authMethod: .guest,
            createdAt: Date(),
            lastSignInAt: Date(),
            isGuest: true,
            biometricEnabled: false
        )
        
        analytics.trackUserSignIn(method: "guest", success: true)

        // Login Flow Success: USER_LOGIN_SUCCESS breadcrumb
        embraceService.addBreadcrumb(message: "USER_LOGIN_SUCCESS_GUEST")

        await handleSuccessfulAuthentication(user: guestUser, span: span)

        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Biometric Authentication
    
    func signInWithBiometrics(for userId: String) async {
        let span = Embrace.client?.buildSpan(
            name: "biometric_sign_in",
            type: .performance
        ).startSpan()
        
        await MainActor.run {
            isLoading = true
            authState = .authenticating
        }
        
        span?.setAttribute(key: "auth.method", value: "biometric")
        span?.setAttribute(key: "user.id", value: userId)

        // Login Flow Start: USER_LOGIN_STARTED breadcrumb
        embraceService.addBreadcrumb(message: "USER_LOGIN_STARTED_BIOMETRIC")

        let result = await biometricManager.authenticateWithBiometrics(
            reason: "Sign in to your account"
        )
        
        switch result {
        case .success(_):
            // Load the user associated with this biometric authentication
            if let savedUser = loadUserById(userId) {
                // Create updated user with new sign-in time
                let updatedUser = AuthenticatedUser(
                    id: savedUser.id,
                    email: savedUser.email,
                    displayName: savedUser.displayName,
                    photoURL: savedUser.photoURL,
                    authMethod: savedUser.authMethod,
                    createdAt: savedUser.createdAt,
                    lastSignInAt: Date(),
                    isGuest: savedUser.isGuest,
                    biometricEnabled: savedUser.biometricEnabled
                )
                
                analytics.trackUserSignIn(method: "biometric", success: true)

                // Login Flow Success: USER_LOGIN_SUCCESS breadcrumb
                embraceService.addBreadcrumb(message: "USER_LOGIN_SUCCESS_BIOMETRIC")

                await handleSuccessfulAuthentication(user: updatedUser, span: span)
            } else {
                analytics.trackUserSignIn(method: "biometric", success: false)

                // Login Flow Failure: USER_LOGIN_FAILED breadcrumb
                embraceService.addBreadcrumb(message: "USER_LOGIN_FAILED_BIOMETRIC")

                await handleAuthenticationError(.unknownError("User not found"), span: span)
            }
            
        case .failure(let error):
            analytics.trackUserSignIn(method: "biometric", success: false)

            // Login Flow Failure: USER_LOGIN_FAILED breadcrumb
            embraceService.addBreadcrumb(message: "USER_LOGIN_FAILED_BIOMETRIC")

            await handleAuthenticationError(error, span: span)
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        let span = Embrace.client?.buildSpan(
            name: "user_sign_out",
            type: .performance
        ).startSpan()
        
        if let user = currentUser {
            span?.setAttribute(key: "user.id", value: user.id)
            span?.setAttribute(key: "auth.method", value: user.authMethod.rawValue)
            span?.setAttribute(key: "session.duration", value: String(Date().timeIntervalSince(user.lastSignInAt)))
        }
        
        // Sign out from Google if applicable
        if currentUser?.authMethod == .google {
            GIDSignIn.sharedInstance.signOut()
        }
        
        // Clear saved user
        UserDefaults.standard.removeObject(forKey: "authenticated_user")
        
        // Update state
        authState = .unauthenticated
        currentUser = nil
        
        analytics.trackUserSignOut()
        analytics.resetUserSession()
        
        span?.end()
        
        Embrace.client?.log(
            "User signed out",
            severity: .info,
            attributes: [
                "auth.method": currentUser?.authMethod.rawValue ?? "unknown"
            ]
        )
    }
    
    // MARK: - Helper Methods
    
    private func handleSuccessfulAuthentication(user: AuthenticatedUser, span: Span?) async {
        await MainActor.run {
            authState = .authenticated(user)
            currentUser = user
            saveUser(user)
        }
        
        // Identify user in Mixpanel
        analytics.identifyUser(userId: user.id, email: user.isGuest ? nil : user.email)
        analytics.updateUserProfile(
            email: user.isGuest ? nil : user.email,
            name: user.displayName,
            plan: user.isGuest ? "guest" : "authenticated"
        )
        
        span?.setAttribute(key: "auth.success", value: "true")
        span?.setAttribute(key: "user.id", value: user.id)
        span?.setAttribute(key: "user.is_guest", value: String(user.isGuest))
        span?.end()
        
        Embrace.client?.log(
            "User authentication successful",
            severity: .info,
            attributes: [
                "auth.method": user.authMethod.rawValue,
                "user.id": user.id,
                "user.is_guest": String(user.isGuest)
            ]
        )
    }
    
    private func handleAuthenticationError(_ error: AuthenticationError, span: Span?) async {
        await MainActor.run {
            authState = .error(error)
        }
        
        span?.setAttribute(key: "auth.success", value: "false")
        span?.setAttribute(key: "error.type", value: String(describing: error))
        span?.setAttribute(key: "error.description", value: error.localizedDescription)
        span?.end()
        
        Embrace.client?.log(
            "Authentication failed",
            severity: .error,
            attributes: [
                "error.type": String(describing: error),
                "error.description": error.localizedDescription
            ]
        )
    }
    
    private func mockEmailAuthentication(email: String, password: String) -> (success: Bool, error: String?) {
        // Simple mock logic - you can customize this for testing different scenarios
        if mockAuthConfig.shouldFailAuthentication() {
            return (false, "Authentication failed")
        }
        
        // Mock validation
        if email.isEmpty || password.isEmpty {
            return (false, "Email and password required")
        }
        
        if !email.contains("@") {
            return (false, "Invalid email format")
        }
        
        if password.count < 6 {
            return (false, "Password too short")
        }
        
        return (true, nil)
    }
    
    private func extractDisplayName(from email: String) -> String {
        let components = email.components(separatedBy: "@")
        return components.first?.capitalized ?? "User"
    }
    
    // MARK: - Persistence
    
    private func saveUser(_ user: AuthenticatedUser) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "authenticated_user")
        }
    }
    
    private func loadSavedUser() -> AuthenticatedUser? {
        guard let userData = UserDefaults.standard.data(forKey: "authenticated_user"),
              let user = try? JSONDecoder().decode(AuthenticatedUser.self, from: userData) else {
            return nil
        }
        
        // Check if session is still valid (for demo, let's say 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        if user.lastSignInAt > thirtyDaysAgo {
            authState = .authenticated(user)
            currentUser = user
            return user
        } else {
            // Session expired
            UserDefaults.standard.removeObject(forKey: "authenticated_user")
            return nil
        }
    }
    
    private func loadUserById(_ userId: String) -> AuthenticatedUser? {
        // In a real app, this would query a database
        // For mock purposes, return the current saved user if IDs match
        if let savedUser = currentUser, savedUser.id == userId {
            return savedUser
        }
        return loadSavedUser()
    }
    
    // MARK: - Configuration Methods
    
    func enableBiometric(for user: AuthenticatedUser) {
        biometricManager.enableBiometric(for: user.id)
        
        let updatedUser = AuthenticatedUser(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
            authMethod: user.authMethod,
            createdAt: user.createdAt,
            lastSignInAt: user.lastSignInAt,
            isGuest: user.isGuest,
            biometricEnabled: true
        )
        
        saveUser(updatedUser)
        currentUser = updatedUser
        authState = .authenticated(updatedUser)
    }
    
    // MARK: - State Queries
    
    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }
    
    var isGuest: Bool {
        currentUser?.isGuest ?? false
    }
    
    var canUseBiometric: Bool {
        biometricManager.canUseBiometric && currentUser?.biometricEnabled == true
    }
}

// MARK: - Mock Configuration

private class MockAuthConfiguration {
    private let failureRate: Double = 0.1 // 10% failure rate for testing
    
    func shouldFailAuthentication() -> Bool {
        Double.random(in: 0...1) < failureRate
    }
    
    func getRandomDelay(fast: Bool = false) -> TimeInterval {
        if fast {
            return Double.random(in: 0.2...0.8)
        } else {
            return Double.random(in: 1.0...3.0)
        }
    }
}