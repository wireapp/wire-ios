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

// MARK: - KeychainItemProtocol

protocol KeychainItemProtocol {
    var id: String { get }
    var getQuery: [CFString: Any] { get }
    func setQuery<T>(value: T) -> [CFString: Any]
}

// MARK: - KeychainManager

public enum KeychainManager {
    // MARK: Internal

    enum AccessLevel {
        case moreRestrictive
        case lessRestrictive
    }

    // MARK: - Keychain access

    static func storeItem(_ item: KeychainItemProtocol, value: some Any) throws {
        WireLogger.keychain.info("storing item (\(item.id))")
        let status = SecItemAdd(item.setQuery(value: value) as CFDictionary, nil)

        guard status == errSecSuccess else {
            WireLogger.keychain.error("storing item (\(item.id)) failed: osstatus \(status)")
            throw Error.failedToStoreItemInKeychain(status)
        }
    }

    static func fetchItem<T>(_ item: KeychainItemProtocol) throws -> T {
        WireLogger.keychain.info("fetching item (\(item.id))")
        var value: CFTypeRef?
        let status = SecItemCopyMatching(item.getQuery as CFDictionary, &value)

        guard status == errSecSuccess else {
            WireLogger.keychain.error("fetching item (\(item.id)) failed: osstatus \(status)")
            throw Error.failedToFetchItemFromKeychain(status)
        }

        return value as! T
    }

    static func deleteItem(_ item: KeychainItemProtocol) throws {
        WireLogger.keychain.info("deleting item (\(item.id))")
        let status = SecItemDelete(item.getQuery as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            WireLogger.keychain.error("deleting item (\(item.id)) failed: osstatus \(status)")
            throw Error.failedToDeleteItemFromKeychain(status)
        }
    }

    // MARK: - Key generation

    static func generateKey(numberOfBytes: UInt = 32) throws -> Data {
        var key = [UInt8](repeating: 0, count: Int(numberOfBytes))
        let status = SecRandomCopyBytes(kSecRandomDefault, key.count, &key)

        guard status == errSecSuccess else {
            throw Error.failedToGenerateKey(status)
        }

        return Data(key)
    }

    static func generatePublicPrivateKeyPair(
        identifier: String,
        accessLevel: AccessLevel
    ) throws -> (privateKey: SecKey, publicKey: SecKey) {
        let protection: CFTypeRef
        var flags: SecAccessControlCreateFlags

        switch accessLevel {
        case .moreRestrictive:
            protection = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            flags = [.userPresence]

        case .lessRestrictive:
            protection = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            flags = []
        }

        if !isRunningOnSimulator {
            flags.insert(.privateKeyUsage)
        }

        var accessError: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            protection,
            flags,
            &accessError
        ) else {
            let error = accessError!.takeRetainedValue() as Swift.Error
            throw error
        }

        guard let identifierData = identifier.data(using: .utf8) else {
            fatalError()
        }

        var attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrAccessControl: access,
                kSecAttrLabel: identifierData,
            ],
        ]

        if !isRunningOnSimulator {
            attributes[kSecAttrTokenID] = kSecAttrTokenIDSecureEnclave
        }

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            let error = error!.takeRetainedValue() as Swift.Error
            throw Error.failedToGeneratePublicPrivateKey(underlyingError: error)
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw Error.failedToCopyPublicKey
        }

        return (privateKey, publicKey)
    }

    // MARK: Private

    private static var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }
}

// MARK: KeychainManager.Error

extension KeychainManager {
    public enum Error: LocalizedError {
        case failedToStoreItemInKeychain(OSStatus)
        case failedToFetchItemFromKeychain(OSStatus)
        case failedToDeleteItemFromKeychain(OSStatus)
        case failedToGenerateKey(OSStatus)
        case failedToGeneratePublicPrivateKey(underlyingError: Swift.Error?)
        case failedToCopyPublicKey

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case let .failedToStoreItemInKeychain(status):
                "failed to store item in keychain, OSStatus: \(status)"

            case let .failedToFetchItemFromKeychain(status):
                "failed to fetch item from keychain, OSStatus: \(status)"

            case let .failedToDeleteItemFromKeychain(status):
                "failed to delete item from keychain, OSStatus: \(status)"

            case let .failedToGenerateKey(status):
                "failed to generate key, OSStatus: \(status)"

            case let .failedToGeneratePublicPrivateKey(underlyingError: error):
                "failed to generate public private key, underlying error: \(error?.localizedDescription ?? "?")"

            case .failedToCopyPublicKey:
                "failed to copy public key"
            }
        }
    }
}
