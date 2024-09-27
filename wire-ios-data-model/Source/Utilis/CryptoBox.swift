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
import WireCryptobox

extension NSManagedObjectContext {
    private static let AccountDirectoryURLKey = "AccountDirectoryURLKey"

    public var accountDirectoryURL: URL? {
        get {
            precondition(zm_isSyncContext, "accountDirectoryURL should only be accessed on the sync context")
            return userInfo[Self.AccountDirectoryURLKey] as? URL
        }

        set {
            precondition(zm_isSyncContext, "accountDirectoryURL should only be accessed on the sync context")
            userInfo[Self.AccountDirectoryURLKey] = newValue
        }
    }

    private static let ApplicationContainerURLKey = "ApplicationContainerURLKey"

    public var applicationContainerURL: URL? {
        get {
            precondition(zm_isSyncContext, "applicationContainerURL should only be accessed on the sync context")
            return userInfo[Self.ApplicationContainerURLKey] as? URL
        }

        set {
            precondition(zm_isSyncContext, "applicationContainerURL should only be accessed on the sync context")
            userInfo[Self.ApplicationContainerURLKey] = newValue
        }
    }

    private static let ZMUserClientKeysStoreKey = "ZMUserClientKeysStore"

    @objc(setupUserKeyStoreInAccountDirectory:applicationContainer:)
    public func setupUserKeyStore(accountDirectory: URL, applicationContainer: URL) {
        if !zm_isSyncContext {
            fatal("Can't initiliazie crypto box on non-sync context")
        }

        let newKeyStore = UserClientKeysStore(
            accountDirectory: accountDirectory,
            applicationContainer: applicationContainer
        )
        userInfo[NSManagedObjectContext.ZMUserClientKeysStoreKey] = newKeyStore
    }

    /// Returns the cryptobox instance associated with this managed object context
    @objc public var zm_cryptKeyStore: UserClientKeysStore! {
        guard zm_isSyncContext else {
            fatal("Can't access key store: Currently not on sync context")
        }

        let keyStore = userInfo.object(forKey: NSManagedObjectContext.ZMUserClientKeysStoreKey)
        return keyStore as? UserClientKeysStore
    }

    @objc
    public func zm_tearDownCryptKeyStore() {
        userInfo.removeObject(forKey: NSManagedObjectContext.ZMUserClientKeysStoreKey)
    }
}

extension FileManager {
    @objc public static let keyStoreFolderPrefix = "otr"

    /// Returns the URL for the keyStore
    @objc(keyStoreURLForAccountInDirectory:createParentIfNeeded:)
    public static func keyStoreURL(accountDirectory: URL, createParentIfNeeded: Bool) -> URL {
        if createParentIfNeeded {
            try! FileManager.default.createAndProtectDirectory(at: accountDirectory)
        }
        return accountDirectory.appendingPathComponent(FileManager.keyStoreFolderPrefix)
    }
}

// MARK: - UserClientKeyStoreError

public enum UserClientKeyStoreError: Error {
    case canNotGeneratePreKeys
    case preKeysCountNeedsToBePositive
}

// MARK: - UserClientKeysStore

/// A storage for cryptographic keys material
@objc(UserClientKeysStore) @objcMembers
open class UserClientKeysStore: NSObject {
    // MARK: Lifecycle

    /// Loads new key store (if not present) or load an existing one
    public init(accountDirectory: URL, applicationContainer: URL) {
        self.cryptoboxDirectory = FileManager.keyStoreURL(
            accountDirectory: accountDirectory,
            createParentIfNeeded: true
        )
        self.applicationContainer = applicationContainer
        self.encryptionContext = UserClientKeysStore.setupContext(in: cryptoboxDirectory)!
    }

    // MARK: Open

    open var encryptionContext: EncryptionContext

    open func deleteAndCreateNewBox() {
        _ = try? FileManager.default.removeItem(at: cryptoboxDirectory)
        encryptionContext = UserClientKeysStore.setupContext(in: cryptoboxDirectory)!
        internalLastPreKey = nil
    }

    open func lastPreKey() throws -> String {
        var error: NSError?
        if internalLastPreKey == nil {
            encryptionContext.perform { [weak self] sessionsDirectory in
                guard let self else { return }
                do {
                    internalLastPreKey = try sessionsDirectory.generateLastPrekey()
                } catch let anError as NSError {
                    error = anError
                }
            }
        }
        if let error {
            throw error
        }
        return internalLastPreKey!
    }

    open func generateMoreKeys(_ count: UInt16 = 1, start: UInt16 = 0) throws -> [(id: UInt16, prekey: String)] {
        if count > 0 {
            var error: Error?
            var newPreKeys: [(id: UInt16, prekey: String)] = []

            let range = preKeysRange(count, start: start)
            encryptionContext.perform { sessionsDirectory in
                do {
                    newPreKeys = try sessionsDirectory.generatePrekeys(range)
                    if newPreKeys.isEmpty {
                        error = UserClientKeyStoreError.canNotGeneratePreKeys
                    }
                } catch let anError as NSError {
                    error = anError
                }
            }
            if let error {
                throw error
            }
            return newPreKeys
        }
        throw UserClientKeyStoreError.preKeysCountNeedsToBePositive
    }

    // MARK: Public

    /// Maximum possible ID for prekey
    public static let MaxPreKeyID = UInt16.max - 1

    /// Folder where the material is stored (managed by Cryptobox)
    public private(set) var cryptoboxDirectory: URL

    public private(set) var applicationContainer: URL

    // MARK: Fileprivate

    /// Fallback prekeys (when no other prekey is available, this will always work)
    fileprivate var internalLastPreKey: String?

    fileprivate func preKeysRange(_ count: UInt16, start: UInt16) -> CountableRange<UInt16> {
        if start >= UserClientKeysStore.MaxPreKeyID - count {
            return 0 ..< count
        }
        return start ..< (start + count)
    }

    // MARK: Private

    private static func setupContext(in directory: URL) -> EncryptionContext? {
        try! FileManager.default.createAndProtectDirectory(at: directory)
        return EncryptionContext(path: directory)
    }
}
