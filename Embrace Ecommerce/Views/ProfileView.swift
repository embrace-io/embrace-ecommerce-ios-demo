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
                        .accessibilityIdentifier("profileLoggedInView")
                } else {
                    // This should not show since authentication is handled at app level
                    EmptyView()
                }
            }
            .accessibilityIdentifier("profileView")
            .navigationTitle("Profile")
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
        }
    }
    
    
    private func loggedInView(user: AuthenticatedUser) -> some View {
        List {
            userInfoSection(user: user)
                .accessibilityIdentifier("profileUserInfoSection")

            Section {
                ProfileMenuRow(
                    icon: "person",
                    title: "Edit Profile",
                    action: {
                        navigationCoordinator.navigate(to: .editProfile)
                    }
                )
                .accessibilityIdentifier("profileEditProfileRow")
                
                ProfileMenuRow(
                    icon: "location",
                    title: "Address Book",
                    action: {
                        navigationCoordinator.navigate(to: .addressBook)
                    }
                )
                .accessibilityIdentifier("profileAddressBookRow")

                ProfileMenuRow(
                    icon: "creditcard",
                    title: "Payment Methods",
                    action: {
                        navigationCoordinator.navigate(to: .paymentMethods)
                    }
                )
                .accessibilityIdentifier("profilePaymentMethodsRow")

                ProfileMenuRow(
                    icon: "clock",
                    title: "Order History",
                    action: {
                        navigationCoordinator.navigate(to: .orderHistory)
                    }
                )
                .accessibilityIdentifier("profileOrderHistoryRow")
            }
            
            Section {
                ProfileMenuRow(
                    icon: "bell",
                    title: "Notifications",
                    action: { }
                )
                .accessibilityIdentifier("profileNotificationsRow")

                ProfileMenuRow(
                    icon: "faceid",
                    title: "Biometric Authentication",
                    action: {
                        showingBiometricSettings = true
                    }
                )
                .accessibilityIdentifier("profileBiometricAuthRow")

                ProfileMenuRow(
                    icon: "network",
                    title: "Network Settings",
                    action: {
                        navigationCoordinator.navigate(to: .networkSettings)
                    }
                )
                .accessibilityIdentifier("profileNetworkSettingsRow")

                ProfileMenuRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Network Debug",
                    action: {
                        navigationCoordinator.navigate(to: .networkDebug)
                    }
                )
                .accessibilityIdentifier("profileNetworkDebugRow")

                ProfileMenuRow(
                    icon: "questionmark.circle",
                    title: "Help & Support",
                    action: { }
                )
                .accessibilityIdentifier("profileHelpSupportRow")

                ProfileMenuRow(
                    icon: "doc.text",
                    title: "Terms & Privacy",
                    action: { }
                )
                .accessibilityIdentifier("profileTermsPrivacyRow")
            }
            
            Section {
                Button(action: signOut) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                            .accessibilityIdentifier("profileSignOutIcon")
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .accessibilityIdentifier("profileSignOutText")
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .accessibilityIdentifier("profileSignOutButton")
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
                                .accessibilityIdentifier("profileUserInitials")
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .accessibilityIdentifier("profileUserImage")
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .accessibilityIdentifier("profileUserDisplayName")

                        if user.isGuest {
                            Text("Guest")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                                .accessibilityIdentifier("profileGuestBadge")
                        }
                    }
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("profileUserEmail")

                    HStack {
                        Text("Signed in with \(user.authMethod.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("profileAuthMethodText")

                        Image(systemName: user.authMethod.iconName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("profileAuthMethodIcon")
                    }
                    .accessibilityIdentifier("profileAuthMethodInfo")
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
                    .accessibilityIdentifier("profileMenuRowIcon")

                Text(title)
                    .foregroundColor(.primary)
                    .accessibilityIdentifier("profileMenuRowTitle")

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("profileMenuRowChevron")
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("profileMenuRow_\(title.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "&", with: "And"))")
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