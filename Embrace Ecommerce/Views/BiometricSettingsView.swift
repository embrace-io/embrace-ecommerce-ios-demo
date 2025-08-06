import SwiftUI

struct BiometricSettingsView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var biometricManager = BiometricAuthenticationManager()
    @State private var isBiometricEnabled = false
    @State private var showingEnableAlert = false
    @State private var showingDisableAlert = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                // Biometric Status Section
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: biometricIconName)
                            .font(.title2)
                            .foregroundColor(biometricStatusColor)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(biometricTitle)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text(biometricStatus)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if biometricManager.canUseBiometric {
                            Toggle("", isOn: $isBiometricEnabled)
                                .labelsHidden()
                                .disabled(isLoading)
                                .onChange(of: isBiometricEnabled) { newValue in
                                    if newValue {
                                        showingEnableAlert = true
                                    } else {
                                        showingDisableAlert = true
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Authentication Method")
                } footer: {
                    Text(biometricFooterText)
                }
                
                if biometricManager.canUseBiometric {
                    // Test Section
                    Section {
                        Button(action: testBiometricAuthentication) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "testtube.2")
                                        .foregroundColor(.blue)
                                }
                                
                                Text("Test Biometric Authentication")
                                    .foregroundColor(.blue)
                                
                                Spacer()
                            }
                        }
                        .disabled(isLoading || !isBiometricEnabled)
                    } header: {
                        Text("Testing")
                    } footer: {
                        Text("Test your biometric authentication to make sure it's working properly.")
                    }
                }
                
                // Security Information
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(.green)
                            Text("Secure Authentication")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            SecurityInfoRow(
                                icon: "lock.shield",
                                text: "Your biometric data never leaves your device"
                            )
                            
                            SecurityInfoRow(
                                icon: "eye.slash",
                                text: "Embrace Store cannot access your biometric information"
                            )
                            
                            SecurityInfoRow(
                                icon: "checkmark.shield",
                                text: "Authentication is processed by iOS securely"
                            )
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Security Information")
                }
            }
            .navigationTitle("Biometric Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadBiometricStatus()
            }
            .alert("Enable Biometric Authentication", isPresented: $showingEnableAlert) {
                Button("Cancel", role: .cancel) {
                    isBiometricEnabled = false
                }
                Button("Enable") {
                    enableBiometric()
                }
            } message: {
                Text("This will allow you to sign in using \(biometricManager.biometricType.displayName) instead of your password.")
            }
            .alert("Disable Biometric Authentication", isPresented: $showingDisableAlert) {
                Button("Cancel", role: .cancel) {
                    isBiometricEnabled = true
                }
                Button("Disable", role: .destructive) {
                    disableBiometric()
                }
            } message: {
                Text("You will need to use your email and password to sign in.")
            }
        }
    }
    
    private var biometricIconName: String {
        if !biometricManager.isAvailable {
            return "xmark.shield"
        }
        
        switch biometricManager.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "xmark.shield"
        }
    }
    
    private var biometricTitle: String {
        if !biometricManager.isAvailable {
            return "Biometric Not Available"
        }
        return biometricManager.biometricType.displayName
    }
    
    private var biometricStatus: String {
        if !biometricManager.isAvailable {
            return "Not supported on this device"
        } else if !biometricManager.isEnrolled {
            return "Not set up in Settings"
        } else if isBiometricEnabled {
            return "Enabled for sign in"
        } else {
            return "Available but not enabled"
        }
    }
    
    private var biometricStatusColor: Color {
        if !biometricManager.isAvailable || !biometricManager.isEnrolled {
            return .gray
        } else if isBiometricEnabled {
            return .green
        } else {
            return .blue
        }
    }
    
    private var biometricFooterText: String {
        if !biometricManager.isAvailable {
            return "Biometric authentication is not available on this device."
        } else if !biometricManager.isEnrolled {
            return "Please set up \(biometricManager.biometricType.displayName) in your device Settings first."
        } else {
            return "When enabled, you can use \(biometricManager.biometricType.displayName) to quickly sign in to your account."
        }
    }
    
    private func loadBiometricStatus() {
        biometricManager.checkBiometricAvailability()
        
        if let user = authManager.currentUser {
            isBiometricEnabled = biometricManager.isBiometricEnabled(for: user.id)
        }
    }
    
    private func enableBiometric() {
        guard let user = authManager.currentUser else { return }
        
        isLoading = true
        
        Task {
            // Test biometric authentication before enabling
            let result = await biometricManager.authenticateWithBiometrics(
                reason: "Enable biometric sign in for your account"
            )
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success(_):
                    biometricManager.enableBiometric(for: user.id)
                    authManager.enableBiometric(for: user)
                    isBiometricEnabled = true
                    
                case .failure(_):
                    isBiometricEnabled = false
                }
            }
        }
    }
    
    private func disableBiometric() {
        guard let user = authManager.currentUser else { return }
        
        biometricManager.disableBiometric(for: user.id)
        isBiometricEnabled = false
    }
    
    private func testBiometricAuthentication() {
        isLoading = true
        
        Task {
            let result = await biometricManager.authenticateWithBiometrics(
                reason: "Test biometric authentication"
            )
            
            await MainActor.run {
                isLoading = false
                
                // Could show success/failure feedback here
                let haptic = UIImpactFeedbackGenerator(style: .medium)
                
                switch result {
                case .success(_):
                    haptic.impactOccurred()
                case .failure(_):
                    let errorHaptic = UINotificationFeedbackGenerator()
                    errorHaptic.notificationOccurred(.error)
                }
            }
        }
    }
}

struct SecurityInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    BiometricSettingsView()
        .environmentObject(AuthenticationManager())
}