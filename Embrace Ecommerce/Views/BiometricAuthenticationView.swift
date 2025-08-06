import SwiftUI

struct BiometricAuthenticationView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var isAuthenticating = false
    @State private var authError: AuthenticationError?
    @State private var selectedUserId: String?
    
    // Mock saved users for demo - in real app, this would come from keychain/secure storage
    @State private var savedUsers: [SavedUser] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Biometric Icon & Status
                VStack(spacing: 16) {
                    Image(systemName: biometricIconName)
                        .font(.system(size: 64))
                        .foregroundColor(canUseBiometric ? .green : .gray)
                        .scaleEffect(isAuthenticating ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatWhileAuthenticating(), value: isAuthenticating)
                    
                    Text(biometricTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(biometricSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                if canUseBiometric && !savedUsers.isEmpty {
                    // Saved Users List
                    VStack(spacing: 16) {
                        Text("Select an account")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(savedUsers, id: \.id) { user in
                                Button(action: {
                                    selectedUserId = user.id
                                    authenticateUser(userId: user.id)
                                }) {
                                    SavedUserRow(user: user, isAuthenticating: isAuthenticating && selectedUserId == user.id)
                                }
                                .disabled(isAuthenticating)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                } else if canUseBiometric {
                    // No saved users, show setup message
                    VStack(spacing: 16) {
                        Text("No saved accounts found")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text("Sign in with email first, then enable biometric authentication in settings.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    if canUseBiometric && !savedUsers.isEmpty {
                        // Mock Biometric Test Button (for demo purposes)
                        Button(action: {
                            performMockAuthentication()
                        }) {
                            HStack {
                                Image(systemName: "testtube.2")
                                Text("Test Biometric (Demo)")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                        .disabled(isAuthenticating)
                        .padding(.horizontal, 32)
                    }
                    
                    // Use Email Instead
                    Button("Use Email Instead") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Biometric Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadSavedUsers()
            }
            .alert("Authentication Error", isPresented: .constant(authError != nil)) {
                Button("OK") {
                    authError = nil
                }
                Button("Try Again") {
                    if let userId = selectedUserId {
                        authenticateUser(userId: userId)
                    }
                }
            } message: {
                Text(authError?.localizedDescription ?? "")
            }
        }
    }
    
    private var canUseBiometric: Bool {
        // This would check BiometricAuthenticationManager in real implementation
        return true // For demo purposes
    }
    
    private var biometricIconName: String {
        if isAuthenticating {
            return "faceid"
        }
        
        // Would get this from BiometricAuthenticationManager
        return "faceid" // Default to Face ID for demo
    }
    
    private var biometricTitle: String {
        if !canUseBiometric {
            return "Biometric Not Available"
        } else if isAuthenticating {
            return "Authenticating..."
        } else {
            return "Sign in with Face ID"
        }
    }
    
    private var biometricSubtitle: String {
        if !canUseBiometric {
            return "Biometric authentication is not available on this device"
        } else if isAuthenticating {
            return "Please complete the biometric authentication"
        } else {
            return "Use Face ID to quickly sign in to your account"
        }
    }
    
    private func loadSavedUsers() {
        // In a real app, this would load from secure keychain storage
        // For demo, create some mock users
        savedUsers = [
            SavedUser(
                id: "user1",
                displayName: "John Doe",
                email: "john.doe@example.com",
                profileImage: nil
            ),
            SavedUser(
                id: "user2",
                displayName: "Guest User",
                email: "guest@example.com",
                profileImage: nil
            )
        ]
    }
    
    private func authenticateUser(userId: String) {
        isAuthenticating = true
        
        Task {
            await authManager.signInWithBiometrics(for: userId)
            
            await MainActor.run {
                isAuthenticating = false
                
                if authManager.isAuthenticated {
                    dismiss()
                } else if case .error(let error) = authManager.authState {
                    authError = error
                }
            }
        }
    }
    
    private func performMockAuthentication() {
        guard let userId = savedUsers.first?.id else { return }
        
        isAuthenticating = true
        selectedUserId = userId
        
        Task {
            // Use mock biometric authentication for demo
            let biometricManager = BiometricAuthenticationManager()
            let result = await biometricManager.mockBiometricAuthentication(shouldSucceed: true)
            
            await MainActor.run {
                isAuthenticating = false
                
                switch result {
                case .success(_):
                    // In real implementation, this would trigger actual sign in
                    // For demo, we'll just dismiss
                    dismiss()
                case .failure(let error):
                    authError = error
                }
            }
        }
    }
}

struct SavedUserRow: View {
    let user: SavedUser
    let isAuthenticating: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image
            AsyncImage(url: user.profileImage) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(.systemGray4))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Authentication Indicator
            if isAuthenticating {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "faceid")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .opacity(isAuthenticating ? 0.6 : 1.0)
    }
}

struct SavedUser {
    let id: String
    let displayName: String
    let email: String
    let profileImage: URL?
}

// Animation extension for continuous pulsing during authentication
extension Animation {
    func repeatWhileAuthenticating() -> Animation {
        self.repeatForever(autoreverses: true)
    }
}

#Preview {
    BiometricAuthenticationView()
        .environmentObject(AuthenticationManager())
}