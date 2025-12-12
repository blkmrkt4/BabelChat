import Foundation
import Network

/// Monitors network connectivity and notifies observers of changes
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.langchat.networkmonitor")

    /// Current connectivity status
    private(set) var isConnected: Bool = true

    /// Connection type
    private(set) var connectionType: ConnectionType = .unknown

    /// Notification posted when connectivity changes
    static let connectivityDidChangeNotification = Notification.Name("NetworkMonitorConnectivityDidChange")

    enum ConnectionType {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    private init() {}

    /// Start monitoring network connectivity
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
            self?.updateConnectionType(path)

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NetworkMonitor.connectivityDidChangeNotification,
                    object: nil,
                    userInfo: ["isConnected": path.status == .satisfied]
                )
            }

            #if DEBUG
            print("🌐 Network status: \(path.status == .satisfied ? "Connected" : "Disconnected")")
            #endif
        }

        monitor.start(queue: queue)
    }

    /// Stop monitoring network connectivity
    func stopMonitoring() {
        monitor.cancel()
    }

    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = .unknown
        }
    }

    /// Check if we can reach Supabase specifically (for initial app launch)
    /// This is a "best effort" check - if NWPathMonitor says we're connected, we trust it
    func checkSupabaseConnectivity() async -> Bool {
        // If NWPathMonitor says we're not connected, return false immediately
        guard isConnected else {
            print("❌ Network path status: not connected")
            return false
        }

        // NWPathMonitor says we're connected - try a lightweight request to verify Supabase
        guard let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/") else {
            // If URL is invalid, but we have network, proceed anyway
            print("⚠️ Invalid Supabase URL, but network is available - proceeding")
            return true
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10.0 // Increased timeout
        request.setValue(SupabaseConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                let isReachable = (200...499).contains(httpResponse.statusCode)
                print("✅ Supabase connectivity check: \(httpResponse.statusCode) - \(isReachable ? "reachable" : "unreachable")")
                return isReachable // Even 4xx means server is reachable
            }
            // Got a response but couldn't parse status - proceed anyway since we have network
            print("⚠️ Supabase response received but couldn't parse - proceeding")
            return true
        } catch {
            // Request failed, but NWPathMonitor says we have network
            // This could be a temporary issue or simulator quirk - proceed anyway
            print("⚠️ Supabase connectivity check failed: \(error)")
            print("   Network path says connected - proceeding anyway")
            return true  // Trust NWPathMonitor over the HTTP check
        }
    }
}
