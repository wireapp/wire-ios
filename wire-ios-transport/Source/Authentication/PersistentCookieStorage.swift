//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

private let cookieName = "zuid"
private let isolationQueue = DispatchQueue(label: "PersistentCookieStorage.isolation")
private var keychainDisabled = false
private var nonPersistedPassword: [String: Any] = [:]
private var currentCookiesPolicy: HTTPCookie.AcceptPolicy = .always

// sourcery: AutoMockable
@objc public protocol PersistentCookieStorageProtocol {
    var authenticationCookieData: Data? { get set }
    var authenticationCookieExpirationDate: Date? { get }
    var hasAuthenticationCookie: Bool { get }
    func deleteKeychainItems()
    @objc(setCookieDataFromResponse:forURL:)
    func setCookieData(from response: HTTPURLResponse, for url: URL)
    @objc(setRequestHeaderFieldsOnRequest:)
    func setRequestHeaderFields(on request: NSMutableURLRequest)
}

@objc
public class PersistentCookieStorage: NSObject, PersistentCookieStorageProtocol {

    @objc
    public let userIdentifier: UUID

    private let useCache: Bool

    private var accountName: String {
        userIdentifier.uuidString
    }

    // MARK: - Creation

    @objc
    public static func storage(
        forUserIdentifier userIdentifier: UUID,
        useCache: Bool
    ) -> PersistentCookieStorage {
        PersistentCookieStorage(userIdentifier: userIdentifier, useCache: useCache)
    }

    public init(userIdentifier: UUID, useCache: Bool) {
        self.userIdentifier = userIdentifier
        self.useCache = useCache
        super.init()
    }

    // MARK: - Public API

    @objc
    public var authenticationCookieData: Data? {
        get {
            var result: Data?
            if findItem(password: &result) {
                return result
            }
            return nil
        }
        set {
            if let data = newValue {
                setItem(data)
            } else {
                deleteItem()
            }
        }
    }

    @objc
    public var authenticationCookieExpirationDate: Date? {
        for cookie in authenticationCookies ?? [] {
            if cookie.name == cookieName {
                return cookie.expiresDate
            }
        }
        return nil
    }

    @objc
    public var hasAuthenticationCookie: Bool {
        authenticationCookieExpirationDate != nil
    }

    @objc
    public func deleteKeychainItems() {
        isolationQueue.sync {
            nonPersistedPassword[accountName] = nil
            ZMKeychain.deleteAllKeychainItems(withAccountName: accountName)
        }
    }

    @objc
    public static func deleteAllKeychainItems() {
        isolationQueue.sync {
            nonPersistedPassword = [:]

            if keychainDisabled {
                return
            }

            ZMKeychain.deleteAllKeychainItems()
        }
    }

    @objc
    public static func hasAccessibleAuthenticationCookieData() -> Bool {
        var success = false
        isolationQueue.sync {
            success = ZMKeychain.hasAccessibleAccountData()
        }
        return success
    }

    // MARK: - HTTPCookie

    @objc
    public static func setCookiesPolicy(_ policy: HTTPCookie.AcceptPolicy) {
        currentCookiesPolicy = policy == .never ? .never : .always
    }

    @objc
    public static func cookiesPolicy() -> HTTPCookie.AcceptPolicy {
        currentCookiesPolicy
    }

    @objc(setCookieDataFromResponse:forURL:)
    public func setCookieData(from response: HTTPURLResponse, for url: URL) {
        if currentCookiesPolicy == .never {
            return
        }

        let cookies = HTTPCookie.cookies(withResponseHeaderFields: response.allHeaderFields as? [String: String] ?? [:], for: url)
        if cookies.isEmpty {
            return
        }

        let properties = cookies.compactMap(\.properties)

        guard (properties.first?[.name] as? String) == cookieName else {
            return
        }

        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(properties, forKey: "properties")
        archiver.finishEncoding()

        var data = archiver.encodedData

        #if os(iOS)
        let secretKey = UserDefaults.cookiesKey()!
        data = data.zmEncryptPrefixingIV(key: secretKey)
        #endif

        authenticationCookieData = data.base64EncodedData()
    }

    @objc(setRequestHeaderFieldsOnRequest:)
    public func setRequestHeaderFields(on request: NSMutableURLRequest) {
        guard let cookies = authenticationCookies else {
            return
        }

        for (field, value) in HTTPCookie.requestHeaderFields(with: cookies) {
            request.addValue(value, forHTTPHeaderField: field)
        }
    }

    // MARK: - Private API

    private var authenticationCookies: [HTTPCookie]? {
        guard var data = authenticationCookieData else {
            return nil
        }

        guard let base64Decoded = Data(base64Encoded: data) else {
            return nil
        }
        data = base64Decoded

        #if os(iOS)
        let secretKey = UserDefaults.cookiesKey()!
        data = data.zmDecryptPrefixedIV(key: secretKey)
        #endif

        let unarchiver: NSKeyedUnarchiver
        do {
            unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = true
        } catch {
            authenticationCookieData = nil
            return nil
        }

        guard let propertyList = unarchiver.decodePropertyList(forKey: "properties"),
              let properties = propertyList as? [[HTTPCookiePropertyKey: Any]] else {
            return nil
        }

        return properties.compactMap(HTTPCookie.init)
    }

    // MARK: - Keychain

    private func findItem(password: inout Data?) -> Bool {
        var success = false
        isolationQueue.sync {
            let cached = nonPersistedPassword[accountName]
            let fetchFromKeychain = (cached == nil)
            password = (cached is NSNull) ? nil : cached as? Data

            if keychainDisabled {
                success = true
                return
            }

            if fetchFromKeychain {
                let result = ZMKeychain.data(forAccount: accountName, fallbackToDefaultGroup: true)

                if let result {
                    password = result
                    addNonPersistedPassword(result)
                    success = true
                }
            } else {
                success = (password != nil)
            }
        }
        return success
    }

    private func addNonPersistedPassword(_ password: Data?) {
        if !useCache {
            return
        }

        nonPersistedPassword[accountName] = password ?? NSNull()
    }

    private func setItem(_ data: Data) {
        if !updateItem(withPassword: data) {
            addItem(withPassword: data)
        }
    }

    @discardableResult
    private func addItem(withPassword password: Data) -> Bool {
        var success = false
        isolationQueue.sync {
            addNonPersistedPassword(password)

            if keychainDisabled {
                success = true
                return
            }
            success = ZMKeychain.setData(password, forAccount: accountName)
        }
        return success
    }

    @discardableResult
    private func updateItem(withPassword password: Data) -> Bool {
        var success = false
        isolationQueue.sync {
            let hasItem = nonPersistedPassword[accountName] != nil
                && !(nonPersistedPassword[accountName] is NSNull)
            if hasItem {
                nonPersistedPassword[accountName] = password
            }

            if keychainDisabled {
                success = hasItem
                return
            }

            success = ZMKeychain.setData(password, forAccount: accountName)
        }

        // now try to read. If we fail to read, it means that the keychain is
        // blocked and it always returns success on an update
        var readPassword: Data?
        let read = findItem(password: &readPassword)

        if !read || readPassword != password {
            isolationQueue.async {
                self.addNonPersistedPassword(password)
            }
        }

        return success
    }

    private func deleteItem() {
        isolationQueue.sync {
            nonPersistedPassword.removeValue(forKey: accountName)

            if keychainDisabled {
                return
            }

            ZMKeychain.deleteAllKeychainItems(withAccountName: accountName)
        }
    }

    // MARK: - Testing

    @objc
    public static func setDoNotPersistToKeychain(_ disabled: Bool) {
        keychainDisabled = disabled
    }

    @objc
    public var isCacheEmpty: Bool {
        nonPersistedPassword.isEmpty
    }
}
