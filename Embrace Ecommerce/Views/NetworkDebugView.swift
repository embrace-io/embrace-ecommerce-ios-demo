import SwiftUI

struct NetworkDebugView: View {
    @StateObject private var networkService = NetworkService.shared
    @StateObject private var reachability = NetworkReachability.shared
    @StateObject private var apiService = APIService.shared
    @State private var metrics: [NetworkService.RequestMetrics] = []
    @State private var showingMetricsDetail = false
    
    var body: some View {
        NavigationView {
            List {
                networkStatusSection
                apiModeSection
                metricsSection
                testSection
            }
            .navigationTitle("Network Debug")
            .onAppear {
                refreshMetrics()
            }
            .refreshable {
                refreshMetrics()
            }
        }
    }
    
    private var networkStatusSection: some View {
        Section("Network Status") {
            HStack {
                Image(systemName: reachability.isConnected ? "wifi" : "wifi.slash")
                    .foregroundColor(reachability.isConnected ? .green : .red)
                
                VStack(alignment: .leading) {
                    Text("Connection: \(reachability.connectionType.description)")
                        .font(.headline)
                    
                    Text("Quality: \(reachability.networkQuality.description)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if reachability.isExpensive {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.orange)
                }
                
                if reachability.isConstrained {
                    Image(systemName: "speedometer")
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    private var apiModeSection: some View {
        Section("API Configuration") {
            Toggle("Use Real API", isOn: $apiService.useRealAPI)
            
            if !apiService.useRealAPI {
                HStack {
                    Text("Mock Network Condition")
                    Spacer()
                    Text("Normal") // This would be connected to MockNetworkService
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var metricsSection: some View {
        Section("Request Metrics") {
            HStack {
                Text("Active Requests")
                Spacer()
                Text("\(networkService.activeRequests.count)")
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("Total Requests")
                Spacer()
                Text("\(metrics.count)")
                    .foregroundColor(.secondary)
            }
            
            if !metrics.isEmpty {
                Button("View All Metrics") {
                    showingMetricsDetail = true
                }
                .foregroundColor(.blue)
            }
            
            Button("Clear Metrics") {
                networkService.clearMetrics()
                refreshMetrics()
            }
            .foregroundColor(.red)
        }
    }
    
    private var testSection: some View {
        Section("Test Requests") {
            Button("Test Product Loading") {
                testProductLoading()
            }
            
            Button("Test Product Search") {
                testProductSearch()
            }
            
            Button("Test Authentication") {
                testAuthentication()
            }
        }
    }
    
    private func refreshMetrics() {
        metrics = networkService.getMetrics()
    }
    
    private func testProductLoading() {
        Task {
            do {
                let products = try await apiService.fetchProducts(limit: 10)
                print("✅ Loaded \(products.count) products")
                refreshMetrics()
            } catch {
                print("❌ Failed to load products: \(error)")
            }
        }
    }
    
    private func testProductSearch() {
        Task {
            do {
                let results = try await apiService.searchProducts(query: "iPhone", limit: 5)
                print("✅ Search returned \(results.count) results")
                refreshMetrics()
            } catch {
                print("❌ Search failed: \(error)")
            }
        }
    }
    
    private func testAuthentication() {
        Task {
            do {
                let response = try await apiService.login(email: "test@example.com", password: "password")
                print("✅ Authentication successful for: \(response.user.email)")
                refreshMetrics()
            } catch {
                print("❌ Authentication failed: \(error)")
            }
        }
    }
}

struct MetricsDetailView: View {
    let metrics: [NetworkService.RequestMetrics]
    
    var body: some View {
        NavigationView {
            List(metrics, id: \.id) { metric in
                MetricRowView(metric: metric)
            }
            .navigationTitle("Request Metrics")
        }
    }
}

struct MetricRowView: View {
    let metric: NetworkService.RequestMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(metric.method) \(metric.endpoint)")
                    .font(.headline)
                
                Spacer()
                
                if let statusCode = metric.statusCode {
                    Text("\(statusCode)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor(statusCode))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            HStack {
                Text("Duration: \(formatDuration(metric.duration))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(DateFormatter.debugTime.string(from: metric.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let error = metric.error {
                Text("Error: \(error.localizedDescription)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func statusColor(_ statusCode: Int) -> Color {
        switch statusCode {
        case 200..<300:
            return .green
        case 300..<400:
            return .orange
        case 400..<500:
            return .red
        case 500...:
            return .purple
        default:
            return .gray
        }
    }
    
    private func formatDuration(_ duration: TimeInterval?) -> String {
        guard let duration = duration else { return "N/A" }
        return String(format: "%.3fs", duration)
    }
}

extension DateFormatter {
    static let debugTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}

#Preview {
    NetworkDebugView()
}