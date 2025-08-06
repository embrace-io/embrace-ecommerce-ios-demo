import Foundation
import Network
import Combine

@available(iOS 12.0, *)
class NetworkReachability: ObservableObject {
    @Published var isConnected = false
    @Published var connectionType: ConnectionType = .none
    @Published var isExpensive = false
    @Published var isConstrained = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    static let shared = NetworkReachability()
    
    enum ConnectionType {
        case none
        case wifi
        case cellular
        case ethernet
        case other
        
        var description: String {
            switch self {
            case .none: return "No Connection"
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .other: return "Other"
            }
        }
        
        var isReliable: Bool {
            switch self {
            case .wifi, .ethernet:
                return true
            case .cellular, .other:
                return false
            case .none:
                return false
            }
        }
    }
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.updateConnection(path)
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    private func updateConnection(_ path: NWPath) {
        Task { @MainActor in
            isConnected = path.status == .satisfied
            isExpensive = path.isExpensive
            isConstrained = path.isConstrained
            
            if path.usesInterfaceType(.wifi) {
                connectionType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                connectionType = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                connectionType = .ethernet
            } else if path.status == .satisfied {
                connectionType = .other
            } else {
                connectionType = .none
            }
        }
    }
    
    func checkConnection() -> Bool {
        return isConnected
    }
    
    func waitForConnection(timeout: TimeInterval = 10.0) async -> Bool {
        if isConnected {
            return true
        }
        
        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            var timeoutTask: Task<Void, Never>?
            
            cancellable = $isConnected
                .first { $0 }
                .sink { _ in
                    timeoutTask?.cancel()
                    continuation.resume(returning: true)
                }
            
            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if !Task.isCancelled {
                    cancellable?.cancel()
                    continuation.resume(returning: false)
                }
            }
        }
    }
}

@available(iOS 12.0, *)
extension NetworkReachability {
    var networkQuality: NetworkQuality {
        guard isConnected else { return .none }
        
        if isConstrained {
            return .poor
        }
        
        if isExpensive {
            return connectionType.isReliable ? .good : .fair
        }
        
        return connectionType.isReliable ? .excellent : .good
    }
}

enum NetworkQuality {
    case none
    case poor
    case fair
    case good
    case excellent
    
    var description: String {
        switch self {
        case .none: return "No Connection"
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    var recommendedTimeout: TimeInterval {
        switch self {
        case .none: return 0
        case .poor: return 60.0
        case .fair: return 45.0
        case .good: return 30.0
        case .excellent: return 15.0
        }
    }
}