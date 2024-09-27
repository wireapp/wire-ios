//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation

// MARK: - ProxyCredentials

public final class ProxyCredentials: NSObject {
    // MARK: Lifecycle

    init(proxy: ProxySettingsProvider, username: String, password: String) {
        self.username = username
        self.password = password
        self.proxy = proxy
    }

    @objc(initWithUsername:password:forProxy:)
    public convenience init?(username: String?, password: String?, proxy: ProxySettingsProvider) {
        guard let username, let password else {
            return nil
        }
        self.init(proxy: proxy, username: username, password: password)
    }

    // MARK: Public

    public var username: String
    public var password: String
    public var proxy: ProxySettingsProvider

    public static func retrieve(for proxy: ProxySettingsProvider) -> ProxyCredentials? {
        do {
            let usernameData = try Keychain.fetchItem(.usernameItem(for: proxy))
            let passwordData = try Keychain.fetchItem(.passwordItem(for: proxy))

            let username = String(decoding: usernameData, as: UTF8.self)
            let password = String(decoding: passwordData, as: UTF8.self)
            return ProxyCredentials(
                username: username,
                password: password,
                proxy: proxy
            )
        } catch {
            return nil
        }
    }

    public static func destroy(for proxy: ProxySettingsProvider) -> Bool {
        do {
            try Keychain.deleteItem(.usernameItem(for: proxy))
            try Keychain.deleteItem(.passwordItem(for: proxy))
        } catch {
            Logging.backendEnvironment.error(error.localizedDescription)
            return false
        }
        return true
    }

    public func persist() throws {
        guard
            let usernameData = username.data(using: .utf8),
            let passwordData = password.data(using: .utf8)
        else { return }

        try? Keychain.deleteItem(.usernameItem(for: proxy))
        try? Keychain.deleteItem(.passwordItem(for: proxy))

        try Keychain.storeItem(.usernameItem(for: proxy), value: usernameData)
        try Keychain.storeItem(.passwordItem(for: proxy), value: passwordData)
    }
}

// MARK: - GenericPasswordKeychainItem

struct GenericPasswordKeychainItem: KeychainItem {
    // MARK: Lifecycle

    init(itemIdentifier: String) {
        self.itemIdentifier = itemIdentifier
    }

    // MARK: Internal

    // MARK: - Methods

    var queryForGettingValue: [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: itemIdentifier,
            kSecReturnData: true,
        ]
    }

    func queryForSetting(value: Data) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: itemIdentifier,
            kSecValueData: value,
        ]
    }

    // MARK: Private

    // MARK: - Properties

    private let itemIdentifier: String
}

extension KeychainItem where Self == GenericPasswordKeychainItem {
    fileprivate static func usernameItem(for proxy: ProxySettingsProvider) -> GenericPasswordKeychainItem {
        GenericPasswordKeychainItem(itemIdentifier: "proxy-\(proxy.host):\(proxy.port)-username")
    }

    fileprivate static func passwordItem(for proxy: ProxySettingsProvider) -> GenericPasswordKeychainItem {
        GenericPasswordKeychainItem(itemIdentifier: "proxy-\(proxy.host):\(proxy.port)-password")
    }
}
