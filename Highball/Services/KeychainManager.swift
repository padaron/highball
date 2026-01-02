import Foundation
import KeychainAccess

enum KeychainManager {
    private static let keychain = Keychain(service: "com.highball.railway")
        .accessibility(.whenUnlockedThisDeviceOnly)

    private static let tokenKey = "railwayAPIToken"

    static func saveToken(_ token: String) throws {
        try keychain.set(token, key: tokenKey)
    }

    static func getToken() -> String? {
        try? keychain.get(tokenKey)
    }

    static func deleteToken() throws {
        try keychain.remove(tokenKey)
    }

    static var hasToken: Bool {
        getToken() != nil
    }
}
