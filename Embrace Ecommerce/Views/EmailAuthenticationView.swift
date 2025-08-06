import SwiftUI

struct EmailAuthenticationView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Binding var isSignUp: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showingPassword = false
    @State private var showingConfirmPassword = false
    
    private var isValidForm: Bool {
        if isSignUp {
            return !email.isEmpty && 
                   email.contains("@") && 
                   password.count >= 6 && 
                   password == confirmPassword &&
                   !displayName.isEmpty
        } else {
            return !email.isEmpty && 
                   email.contains("@") && 
                   password.count >= 6
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(isSignUp ? "Join Embrace Store today" : "Welcome back to Embrace Store")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)
                    
                    // Form
                    VStack(spacing: 20) {
                        
                        if isSignUp {
                            FormField(
                                title: "Display Name",
                                text: $displayName,
                                placeholder: "Enter your name",
                                icon: "person.fill"
                            )
                        }
                        
                        FormField(
                            title: "Email Address",
                            text: $email,
                            placeholder: "Enter your email",
                            icon: "envelope.fill",
                            keyboardType: .emailAddress
                        )
                        
                        FormField(
                            title: "Password",
                            text: $password,
                            placeholder: "Enter your password",
                            icon: "lock.fill",
                            isSecure: !showingPassword,
                            showPasswordToggle: true,
                            isPasswordVisible: $showingPassword
                        )
                        
                        if isSignUp {
                            FormField(
                                title: "Confirm Password",
                                text: $confirmPassword,
                                placeholder: "Confirm your password",
                                icon: "lock.fill",
                                isSecure: !showingConfirmPassword,
                                showPasswordToggle: true,
                                isPasswordVisible: $showingConfirmPassword
                            )
                            
                            if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text("Passwords don't match")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Submit Button
                    Button(action: handleSubmit) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidForm ? Color.blue : Color.gray)
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: isValidForm ? 4 : 0, x: 0, y: 2)
                    }
                    .disabled(!isValidForm || authManager.isLoading)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    
                    // Toggle between Sign In / Sign Up
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSignUp.toggle()
                            // Clear form when switching
                            clearForm()
                        }
                    }) {
                        HStack {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.secondary)
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Authentication Error", isPresented: .constant(showError)) {
                Button("OK") {
                    // Could implement error handling here
                }
            } message: {
                Text(errorMessage)
            }
        }
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
    
    private func handleSubmit() {
        Task {
            if isSignUp {
                await authManager.registerWithEmail(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password,
                    displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            } else {
                await authManager.signInWithEmail(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )
            }
            
            // Close the sheet if authentication was successful
            if authManager.isAuthenticated {
                dismiss()
            }
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        showingPassword = false
        showingConfirmPassword = false
    }
}

struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var showPasswordToggle: Bool = false
    @Binding var isPasswordVisible: Bool
    
    init(title: String, text: Binding<String>, placeholder: String, icon: String, keyboardType: UIKeyboardType = .default, isSecure: Bool = false, showPasswordToggle: Bool = false, isPasswordVisible: Binding<Bool> = .constant(false)) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.showPasswordToggle = showPasswordToggle
        self._isPasswordVisible = isPasswordVisible
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .autocapitalization(keyboardType == .emailAddress ? .none : .sentences)
                            .disableAutocorrection(keyboardType == .emailAddress)
                    }
                }
                .textFieldStyle(PlainTextFieldStyle())
                
                if showPasswordToggle {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

#Preview {
    EmailAuthenticationView(isSignUp: .constant(false))
        .environmentObject(AuthenticationManager())
}