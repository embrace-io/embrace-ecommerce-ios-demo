import SwiftUI

struct NetworkSettingsView: View {
    @StateObject private var networkService = MockNetworkService.shared
    @State private var selectedCondition: NetworkCondition = .normal
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Network Simulation")) {
                    Picker("Network Condition", selection: $selectedCondition) {
                        ForEach(NetworkCondition.allCases, id: \.self) { condition in
                            VStack(alignment: .leading) {
                                Text(condition.rawValue)
                                    .font(.headline)
                                Text(condition.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(condition)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .onChange(of: selectedCondition) { _, newValue in
                        networkService.setNetworkCondition(newValue)
                    }
                }
                
                Section(header: Text("Current Settings")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(networkService.isOnline ? "Online" : "Offline")
                            .foregroundColor(networkService.isOnline ? .green : .red)
                    }
                    
                    HStack {
                        Text("Base Delay")
                        Spacer()
                        Text("\(String(format: "%.1f", networkService.config.baseDelay))s")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Slow Delay")
                        Spacer()
                        Text("\(String(format: "%.1f", networkService.config.slowDelay))s")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Failure Rate")
                        Spacer()
                        Text("\(Int(networkService.config.failureRate * 100))%")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Test Network Requests")) {
                    Button("Test Product Loading") {
                        testProductLoading()
                    }
                    
                    Button("Test Search") {
                        testSearch()
                    }
                    
                    Button("Test Authentication") {
                        testAuthentication()
                    }
                }
            }
            .navigationTitle("Network Settings")
            .onAppear {
                selectedCondition = getCurrentCondition()
            }
        }
    }
    
    private func getCurrentCondition() -> NetworkCondition {
        if !networkService.isOnline {
            return .offline
        }
        
        switch networkService.config.baseDelay {
        case 0.0...0.3:
            return .optimal
        case 0.3...1.0:
            return .normal
        case 1.0...3.0:
            return .poor
        default:
            return .unreliable
        }
    }
    
    private func testProductLoading() {
        Task {
            do {
                let products: [Product] = try await networkService.simulateRequest(
                    endpoint: "/products/featured",
                    responseType: [Product].self
                )
                print("✅ Successfully loaded \(products.count) products")
            } catch {
                print("❌ Failed to load products: \(error.localizedDescription)")
            }
        }
    }
    
    private func testSearch() {
        Task {
            do {
                let results: [Product] = try await networkService.simulateRequest(
                    endpoint: "/products/search?q=phone",
                    responseType: [Product].self
                )
                print("✅ Search returned \(results.count) results")
            } catch {
                print("❌ Search failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func testAuthentication() {
        Task {
            do {
                let user: User = try await networkService.simulateRequest(
                    endpoint: "/auth/login",
                    responseType: User.self
                )
                print("✅ Authentication successful for user: \(user.email)")
            } catch {
                print("❌ Authentication failed: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NetworkSettingsView()
}