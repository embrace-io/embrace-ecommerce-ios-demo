import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingBiometricSettings = false
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            VStack(spacing: 0) {
                if let user = authManager.currentUser {
                    loggedInView(user: user)
                } else {
                    // This should not show since authentication is handled at app level
                    EmptyView()
                }
            }
            .navigationTitle("Profile")
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
        }
    }
    
    
    private func loggedInView(user: AuthenticatedUser) -> some View {
        List {
            userInfoSection(user: user)
            
            Section {
                ProfileMenuRow(
                    icon: "person",
                    title: "Edit Profile",
                    action: {
                        navigationCoordinator.navigate(to: .editProfile)
                    }
                )
                
                ProfileMenuRow(
                    icon: "location",
                    title: "Address Book",
                    action: {
                        navigationCoordinator.navigate(to: .addressBook)
                    }
                )
                
                ProfileMenuRow(
                    icon: "creditcard",
                    title: "Payment Methods",
                    action: {
                        navigationCoordinator.navigate(to: .paymentMethods)
                    }
                )
                
                ProfileMenuRow(
                    icon: "clock",
                    title: "Order History",
                    action: {
                        navigationCoordinator.navigate(to: .orderHistory)
                    }
                )
            }
            
            Section {
                ProfileMenuRow(
                    icon: "bell",
                    title: "Notifications",
                    action: { }
                )
                
                ProfileMenuRow(
                    icon: "faceid",
                    title: "Biometric Authentication",
                    action: {
                        showingBiometricSettings = true
                    }
                )
                
                ProfileMenuRow(
                    icon: "network",
                    title: "Network Settings",
                    action: {
                        navigationCoordinator.navigate(to: .networkSettings)
                    }
                )
                
                ProfileMenuRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Network Debug",
                    action: {
                        navigationCoordinator.navigate(to: .networkDebug)
                    }
                )
                
                ProfileMenuRow(
                    icon: "questionmark.circle",
                    title: "Help & Support",
                    action: { }
                )
                
                ProfileMenuRow(
                    icon: "doc.text",
                    title: "Terms & Privacy",
                    action: { }
                )
            }
            
            Section {
                Button(action: signOut) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                        Text("Sign Out")
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .sheet(isPresented: $showingBiometricSettings) {
            BiometricSettingsView()
                .environmentObject(authManager)
        }
    }
    
    private func userInfoSection(user: AuthenticatedUser) -> some View {
        Section {
            HStack(spacing: 16) {
                // Profile Image
                AsyncImage(url: URL(string: user.photoURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            Text(user.displayName.prefix(2).uppercased())
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if user.isGuest {
                            Text("Guest")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Signed in with \(user.authMethod.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: user.authMethod.iconName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .profile:
            ProfileView()
        case .editProfile:
            EditProfileView()
                .environmentObject(authManager)
        case .addressBook:
            AddressBookView()
        case .paymentMethods:
            PaymentMethodsView()
        case .orderHistory:
            OrderHistoryView()
        case .networkSettings:
            NetworkSettingsView()
        case .networkDebug:
            NetworkDebugView()
        default:
            Text("Coming Soon")
                .navigationTitle("Coming Soon")
        }
    }
    
    private func signOut() {
        authManager.signOut()
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension DateFormatter {
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(NavigationCoordinator())
    }
}