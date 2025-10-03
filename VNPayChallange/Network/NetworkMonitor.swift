import Foundation
import Network
import SystemConfiguration

final class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")

    private var lastStatus: Bool = false
    private var hasLastStatus: Bool = false

    var onStatusChange: ((InternetStatus) -> Void)?

    private init(){}

    func startMonitoring(){
        guard monitor == nil else { return }

        let m = NWPathMonitor()
        self.monitor = m
        m.start(queue: queue)

        m.pathUpdateHandler = { [weak self ] path in 
            guard let self = self else { return }

            let connected = (path.status == .satisfied)
            if !self.hasLastStatus || self.lastStatus != connected {
                self.lastStatus = connected
                self.hasLastStatus = true

                if connected {
                    self.checkInternetAvailability { status in
                        self.onStatusChange?(status)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.onStatusChange?(.noConnection)
                    }
                }
            }
        }
    }

    func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
    }

    private func checkInternetAvailability(completion: @escaping (InternetStatus) -> Void) {
        guard let url = URL(string: "https://google.com") else {
            completion(.unavailable)
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: request) { _, response, error in 
            var status: InternetStatus = .unavailable
            
            if error == nil, let httpResponse = response as? HTTPURLResponse {
                status = (httpResponse.statusCode == 200)
                        ? .connected
                        : .other
            }

            DispatchQueue.main.async {
                completion(status)
            }
        }.resume()
    }
}