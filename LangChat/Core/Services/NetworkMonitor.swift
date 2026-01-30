import Foundation
import Network

/// Monitors network connectivity and notifies observers of changes
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.langchat.networkmonitor")

    /// Current connectivity status
    private(set) var isConnected: Bool = true

    /// Whether NWPathMonitor has reported at least once
    private(set) var hasReceivedInitialStatus: Bool = false

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
            self?.hasReceivedInitialStatus = true
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

    /// Wait for NWPathMonitor to report its initial network status
    func waitForInitialStatus(timeout: TimeInterval = 3.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !hasReceivedInitialStatus && Date() < deadline {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
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
        guard let url = URL(string: "\(Config.supabaseURL)/rest/v1/") else {
            // If URL is invalid, but we have network, proceed anyway
            print("⚠️ Invalid Supabase URL, but network is available - proceeding")
            return true
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10.0 // Increased timeout
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")

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
            // Request failed - we can't reach Supabase, show offline screen
            // Even if NWPathMonitor says we have network, Supabase is what matters for this app
            print("❌ Supabase connectivity check failed: \(error)")
            print("   Cannot reach Supabase - showing offline screen")
            return false
        }
    }
}
