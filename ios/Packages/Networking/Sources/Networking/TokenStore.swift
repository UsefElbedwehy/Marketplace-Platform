import Foundation
import Security

/// Owns the session in the Keychain (ADR-0007). An **actor** so concurrent
/// callers (the auth interceptor on every outgoing request, sign-in, sign-out)
/// never race on the same Keychain item — single-flight by construction.
public actor TokenStore {
    private let service: String
    private let account = "current-session"

    public init(service: String = "com.marketplaceplatform.app.session") {
        self.service = service
    }

    public func save(_ session: StoredSession) throws {
        let data = try JSONEncoder().encode(session)
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.write(status) }
    }

    public func load() -> StoredSession? {
        var readQuery = query
        readQuery[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(readQuery as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(StoredSession.self, from: data)
    }

    public func clear() {
        SecItemDelete(query as CFDictionary)
    }

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

public enum KeychainError: Error, Equatable {
    case write(OSStatus)
}
