import SwiftUI
import GoogleSignInSwift

struct AuthenticationView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingSignUp = false
    @State private var showingBiometricAuth = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // App Logo/Header
                VStack(spacing: 16) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                        .accessibilityIdentifier("authAppLogo")

                    Text("Embrace Store")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .accessibilityIdentifier("authAppTitle")

                    Text("Welcome back! Please sign in to continue.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("authWelcomeMessage")
                }
                .padding(.bottom, 32)
                .accessibilityIdentifier("authHeader")
                
                // Authentication Options
                VStack(spacing: 16) {

                    // Email Sign In Button
                    NavigationLink(destination: EmailAuthenticationView(isSignUp: $showingSignUp)) {
                        AuthenticationButton(
                            title: "Sign In with Email",
                            icon: "envelope.fill",
                            backgroundColor: .blue
                        )
                    }
                    .accessibilityIdentifier("authEmailSignInButton")

                    // Google Sign In Button
                    GoogleSignInButton(scheme: .dark, style: .wide, state: .normal) {
                        Task {
                            await authManager.signInWithGoogle()
                        }
                    }
                    .frame(height: 50)
                    .disabled(authManager.isLoading)
                    .accessibilityIdentifier("authGoogleSignInButton")

                    // Biometric Authentication (if available)
                    if canShowBiometricAuth {
                        Button(action: {
                            showingBiometricAuth = true
                        }) {
                            AuthenticationButton(
                                title: "Sign In with Biometrics",
                                icon: "faceid",
                                backgroundColor: .green
                            )
                        }
                        .sheet(isPresented: $showingBiometricAuth) {
                            BiometricAuthenticationView()
                        }
                        .accessibilityIdentifier("authBiometricSignInButton")
                    }

                    // Guest Checkout
                    Button(action: {
                        Task {
                            await authManager.continueAsGuest()
                        }
                    }) {
                        AuthenticationButton(
                            title: "Continue as Guest",
                            icon: "person.crop.circle",
                            backgroundColor: .gray
                        )
                    }
                    .disabled(authManager.isLoading)
                    .accessibilityIdentifier("authGuestButton")
                }
                .padding(.horizontal, 32)
                .accessibilityIdentifier("authOptionsSection")
                
                Spacer()
                
                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("authSignUpPrompt")

                    Button("Sign Up") {
                        showingSignUp = true
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
                    .accessibilityIdentifier("authSignUpButton")
                }
                .padding(.bottom, 32)
                .accessibilityIdentifier("authSignUpSection")
            }
            .accessibilityIdentifier("authenticationView")
            .accessibilityElement(children: .contain)
            .navigationBarHidden(true)
            .overlay(
                loadingOverlay
                    .accessibilityIdentifier("authLoadingOverlay"),
                alignment: .center
            )
            .alert("Authentication Error", isPresented: .constant(showError)) {
                Button("OK") {
                    // Reset error state would go here
                }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingSignUp) {
                EmailAuthenticationView(isSignUp: $showingSignUp)
            }
        }
    }
    
    private var canShowBiometricAuth: Bool {
        // Only show if we have a saved user who has biometric enabled
        // For demo purposes, we'll show it after someone has signed in at least once
        UserDefaults.standard.data(forKey: "authenticated_user") != nil
    }
    
    private var showError: Bool {
        if case .error = authManager.authState {
            return true
        }
        return false
    }
    
    private var errorMessage: String {
        if case .error(let error) = authManager.authState {
            return error.localizedDescription
        }
        return ""
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        if authManager.isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .accessibilityIdentifier("authLoadingSpinner")
                Text("Signing in...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("authLoadingText")
            }
            .padding(24)
            .background(.regularMaterial)
            .cornerRadius(16)
        }
    }
}

struct AuthenticationButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .accessibilityIdentifier("authButtonIcon_\(icon)")

            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .accessibilityIdentifier("authButtonTitle_\(title.replacingOccurrences(of: " ", with: ""))")

            Spacer()
        }
        .foregroundColor(.white)
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: backgroundColor.opacity(0.3), radius: 4, x: 0, y: 2)
        .accessibilityIdentifier("authButton_\(title.replacingOccurrences(of: " ", with: ""))")
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}