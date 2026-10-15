import Foundation

enum APIConfig {
    private static let localURL = URL(string: "http://localhost:8080")!

    /// Simulator berjalan di Mac, jadi memakai `localhost`. iPhone asli memakai alamat
    /// dari `ManoteDeviceAPIBaseURL` di `Manote-Info.plist`.
    static let baseURL: URL = {
        #if targetEnvironment(simulator)
        return localURL
        #else
        let value = Bundle.main.object(forInfoDictionaryKey: "ManoteDeviceAPIBaseURL") as? String
        return value.flatMap(URL.init(string:)) ?? localURL
        #endif
    }()
}
