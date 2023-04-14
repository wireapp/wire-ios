//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

protocol KeychainItemProtocol {
    var id: String { get }
    var getQuery: [CFString: Any] { get }
    func setQuery<T>(value: T) -> [CFString: Any]
}

public enum KeychainManager {
    public enum Error: Swift.Error {
        case failedToStoreItemInKeychain(OSStatus)
        case failedToFetchItemFromKeychain(OSStatus)
        case failedToDeleteItemFromKeychain(OSStatus)
        case failedToGenerateKey(OSStatus)
        case failedToGeneratePublicPrivateKey(underlyingError: Swift.Error?)
        case failedToCopyPublicKey
    }

    // MARK: - Keychain access
    static func storeItem<T>(_ item: KeychainItemProtocol, value: T) throws {
        WireLogger.keychain.info("store item (\(item.id))")
        let status = SecItemAdd(item.setQuery(value: value) as CFDictionary, nil)
        guard status == errSecSuccess else {
            WireLogger.keychain.error("store item (\(item.id)) failed: osstatus \(status)")
            throw Error.failedToStoreItemInKeychain(status)
        }
    }

    static func fetchItem<T>(_ item: KeychainItemProtocol) throws -> T {
        WireLogger.keychain.info("fetch item (\(item.id))")
        var value: CFTypeRef?
        let status = SecItemCopyMatching(item.getQuery as CFDictionary, &value)
        guard status == errSecSuccess else {
            WireLogger.keychain.error("fetch item (\(item.id)) failed: osstatus \(status)")
            throw Error.failedToFetchItemFromKeychain(status)
        }
        return value as! T
    }

    static func deleteItem(_ item: KeychainItemProtocol) throws {
        WireLogger.keychain.info("delete item (\(item.id))")
        let status = SecItemDelete(item.getQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            WireLogger.keychain.error("delete item (\(item.id)) failed: osstatus \(status)")
            throw Error.failedToDeleteItemFromKeychain(status)
        }
    }

    // MARK: - Key generation
    static func generateKey(numberOfBytes: UInt = 32) throws -> Data {
        WireLogger.keychain.info("generate key (\(numberOfBytes) bytes)")
        var key = [UInt8](repeating: 0, count: Int(numberOfBytes))
        let status = SecRandomCopyBytes(kSecRandomDefault, key.count, &key)
        guard status == errSecSuccess else {
            WireLogger.keychain.info("generate key (\(numberOfBytes) bytes) failed: osstatus \(status)")
            throw Error.failedToGenerateKey(status)
        }
        return Data(key)
    }

    static func generatePublicPrivateKeyPair(identifier: String) throws -> (privateKey: SecKey, publicKey: SecKey) {
        #if targetEnvironment(simulator)
        return try generateSimulatorPublicPrivateKeyPair(identifier: identifier)
        #else
        return try generateSecureEnclavePublicPrivateKeyPair(identifier: identifier)
        #endif
    }

    private static func generateSecureEnclavePublicPrivateKeyPair(identifier: String) throws -> (privateKey: SecKey, publicKey: SecKey) {
        WireLogger.keychain.info("generate secure enclave public private keypair for id (\(identifier))")
        var accessError: Unmanaged<CFError>?

        guard
            let access = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [.privateKeyUsage, .userPresence],
                &accessError
            )
        else {
            let error = accessError!.takeRetainedValue() as Swift.Error
            WireLogger.keychain.error("generate secure enclave public private keypair for id (\(identifier)) failed to create acceess control: \(error)")
            throw Error.failedToGeneratePublicPrivateKey(underlyingError: error)
        }

        guard let identifierData = identifier.data(using: .utf8) else { fatalError() }
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrAccessControl: access,
                kSecAttrLabel: identifierData
            ]
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            let error = error!.takeRetainedValue() as Swift.Error
            WireLogger.keychain.error("generate secure enclave public private keypair for id (\(identifier)) failed to create private key: \(error)")
            throw Error.failedToGeneratePublicPrivateKey(underlyingError: error)
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            WireLogger.keychain.error("generate secure enclave public private keypair for id (\(identifier)) failed to copy public key")
            throw Error.failedToCopyPublicKey
        }

        return (privateKey, publicKey)
    }

    private static func generateSimulatorPublicPrivateKeyPair(identifier: String) throws -> (privateKey: SecKey, publicKey: SecKey) {
        WireLogger.keychain.info("generate simulator public private keypair for id (\(identifier))")
        var accessError: Unmanaged<CFError>?
        guard
            let access = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [.userPresence],
                &accessError
            )
        else {
            let error = accessError!.takeRetainedValue() as Swift.Error
            WireLogger.keychain.error("generate simulator public private keypair for id (\(identifier)) failed to create acceess control: \(error)")
            throw Error.failedToGeneratePublicPrivateKey(underlyingError: error)
        }

        guard let identifierData = identifier.data(using: .utf8) else { fatalError() }
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrAccessControl: access,
                kSecAttrLabel: identifierData
            ]
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            // Notice: accessError is nil when test with iOS 15 simulator. ref:https://wearezeta.atlassian.net/browse/SQCORE-1188
            let error = accessError?.takeRetainedValue()
            WireLogger.keychain.error("generate simulator public private keypair for id (\(identifier)) failed to create private key: \(error)")
            throw Error.failedToGeneratePublicPrivateKey(underlyingError: error)
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            WireLogger.keychain.error("generate simulator public private keypair for id (\(identifier)) failed to create copy public key")
            throw Error.failedToCopyPublicKey
        }

        return (privateKey, publicKey)
    }
}
