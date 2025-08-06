import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var user: User?
    @State private var isLoggedIn = false
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            VStack(spacing: 0) {
                if isLoggedIn, let user = user {
                    loggedInView(user: user)
                } else {
                    guestView
                }
            }
            .navigationTitle("Profile")
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
            .onAppear {
                loadUserData()
            }
        }
    }
    
    private var guestView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "person.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                VStack(spacing: 8) {
                    Text("Welcome to Embrace Store")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Sign in to access your account and get personalized recommendations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            VStack(spacing: 12) {
                Button("Sign In") {
                    showSignIn()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                
                Button("Create Account") {
                    showSignUp()
                }
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                
                Button("Continue as Guest") {
                    continueAsGuest()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private func loggedInView(user: User) -> some View {
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
    }
    
    private func userInfoSection(user: User) -> some View {
        Section {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("\(user.firstName.first?.uppercased() ?? "")\(user.lastName.first?.uppercased() ?? "")")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(user.firstName) \(user.lastName)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !user.isGuest {
                        Text("Member since \(DateFormatter.monthYear.string(from: user.dateJoined))")
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
            Text("Edit Profile")
                .navigationTitle("Edit Profile")
        case .addressBook:
            Text("Address Book")
                .navigationTitle("Address Book")
        case .paymentMethods:
            Text("Payment Methods")
                .navigationTitle("Payment Methods")
        case .orderHistory:
            Text("Order History")
                .navigationTitle("Order History")
        case .networkSettings:
            NetworkSettingsView()
        case .networkDebug:
            NetworkDebugView()
        default:
            Text("Coming Soon")
                .navigationTitle("Coming Soon")
        }
    }
    
    private func loadUserData() {
        if let userData = UserDefaults.standard.data(forKey: "current_user"),
           let decodedUser = try? JSONDecoder().decode(User.self, from: userData) {
            user = decodedUser
            isLoggedIn = true
        } else {
            isLoggedIn = false
        }
    }
    
    private func showSignIn() {
        user = MockDataService.shared.mockLogin()
        isLoggedIn = true
    }
    
    private func showSignUp() {
        showSignIn()
    }
    
    private func continueAsGuest() {
        user = MockDataService.shared.mockGuestLogin()
        isLoggedIn = true
    }
    
    private func signOut() {
        MockDataService.shared.logout()
        user = nil
        isLoggedIn = false
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