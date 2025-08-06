import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @StateObject private var profileManager = UserProfileManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                profileImageSection
                personalInfoSection
                contactInfoSection
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(profileManager.isLoading || !isFormValid)
                }
            }
            .disabled(profileManager.isLoading)
            .alert("Profile Update", isPresented: $showingAlert) {
                Button("OK") {
                    if isSuccess {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadCurrentUserData()
            }
        }
    }
    
    private var profileImageSection: some View {
        Section {
            HStack {
                Spacer()
                
                VStack {
                    AsyncImage(url: URL(string: authManager.currentUser?.photoURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .overlay(
                                Text("\(firstName.prefix(1))\(lastName.prefix(1))".uppercased())
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            )
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    Button("Change Photo") {
                        // TODO: Implement photo picker
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.vertical)
        }
    }
    
    private var personalInfoSection: some View {
        Section("Personal Information") {
            HStack {
                Image(systemName: "person")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .autocapitalization(.words)
            }
            
            HStack {
                Image(systemName: "person")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .autocapitalization(.words)
            }
        }
    }
    
    private var contactInfoSection: some View {
        Section("Contact Information") {
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disabled(authManager.currentUser?.authMethod != .email)
            }
            
            if authManager.currentUser?.authMethod != .email {
                Text("Email cannot be changed for \(authManager.currentUser?.authMethod.displayName ?? "this") accounts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "phone")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField("Phone Number", text: $phoneNumber)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }
        }
    }
    
    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@")
    }
    
    private func loadCurrentUserData() {
        guard let user = authManager.currentUser else { return }
        
        // Extract names from display name
        let names = user.displayName.components(separatedBy: " ")
        firstName = names.first ?? ""
        lastName = names.dropFirst().joined(separator: " ")
        email = user.email
        phoneNumber = "" // Phone number would come from user profile service
    }
    
    private func saveProfile() async {
        let success = await profileManager.updateUserProfile(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phoneNumber
        )
        
        if success {
            alertMessage = "Profile updated successfully!"
            isSuccess = true
        } else {
            alertMessage = profileManager.errorMessage ?? "Failed to update profile. Please try again."
            isSuccess = false
        }
        
        showingAlert = true
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthenticationManager())
}