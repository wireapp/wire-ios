//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
    
    fileprivate static let ZMUserClientKeysStoreKey = "ZMUserClientKeysStore"
    
    @objc(setupUserKeyStoreInSharedContainer:withAccountIdentifier:)
    public func setupUserKeyStore(in sharedContainerDirectory: URL, for accountIdentifier: UUID) -> Void
    {
        if !self.zm_isSyncContext {
            fatal("Can't initiliazie crypto box on non-sync context")
        }

        let newKeyStore = UserClientKeysStore(in: sharedContainerDirectory, accountIdentifier: accountIdentifier)
        self.userInfo[NSManagedObjectContext.ZMUserClientKeysStoreKey] = newKeyStore
    }
    
    /// Returns the cryptobox instance associated with this managed object context
    public var zm_cryptKeyStore : UserClientKeysStore! {
        if !self.zm_isSyncContext {
            fatal("Can't access key store: Currently not on sync context")
        }
        let keyStore = self.userInfo.object(forKey: NSManagedObjectContext.ZMUserClientKeysStoreKey)
        if let keyStore = keyStore as? UserClientKeysStore {
            return keyStore
        } else {
            fatal("Can't access key store: not keystore found.")
        }
    }
    
    public func zm_tearDownCryptKeyStore() {
        self.userInfo.removeObject(forKey: NSManagedObjectContext.ZMUserClientKeysStoreKey)
    }
}

public extension FileManager {

    public static let keyStoreFolderPrefix = "otr"
    
    /// Returns the URL for the keyStore
    public static func keyStoreURLForAccount(with accountIdentifier: UUID?, in sharedContainerURL: URL, createParentIfNeeded: Bool) -> URL {
        var url = sharedContainerURL
        if let accountIdentifier = accountIdentifier {
            url.appendPathComponent(accountIdentifier.uuidString, isDirectory:true)
        }
        if createParentIfNeeded && !FileManager.default.fileExists(atPath: url.path) {
            try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        return url.appendingPathComponent(FileManager.keyStoreFolderPrefix)
    }
    
}

public enum UserClientKeyStoreError: Error {
    case canNotGeneratePreKeys
    case preKeysCountNeedsToBePositive
}

@objc(UserClientKeysStore)
open class UserClientKeysStore: NSObject {
    
    open static let MaxPreKeyID : UInt16 = UInt16.max-1;
    open var encryptionContext : EncryptionContext
    fileprivate var internalLastPreKey: String?
    public private(set) var cryptoboxDirectoryURL : URL
    public private(set) var sharedContainerURL: URL
    
    public init(in sharedContainerURL: URL, accountIdentifier: UUID) {
        cryptoboxDirectoryURL = FileManager.keyStoreURLForAccount(with: accountIdentifier, in: sharedContainerURL, createParentIfNeeded: true)
                                                  
        self.sharedContainerURL = sharedContainerURL
        encryptionContext = UserClientKeysStore.setupContext(in: cryptoboxDirectoryURL,
                                                             sharedContainer: sharedContainerURL)!
    }
    
    static func setupContext(in directory:URL, sharedContainer: URL) -> EncryptionContext? {
        let encryptionContext : EncryptionContext
        do {
            /// migrate old directories
            var didMigrate = false
            if needToMigrateIdentity(sharedContainerURL: sharedContainer) {
                
                legacyDirectories(sharedContainerURL: sharedContainer).forEach{
                    guard FileManager.default.fileExists(atPath: $0.path) else { return }
                    if !didMigrate {
                        do {
                            try FileManager.default.moveItem(at: $0, to: directory)
                            didMigrate = true
                        }
                        catch let err {
                            fatal("Cannot move legacy directory: \(err)")
                        }
                    }
                    else {
                        do {
                            try FileManager.default.removeItem(at: $0)
                        }
                        catch let err {
                            fatal("Cannot removing older legacy directory: \(err)")
                        }
                    }
                }
            }
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            }
            
            encryptionContext = EncryptionContext(path: directory)
            try (directory as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)

            let attributes = [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            try FileManager.default.setAttributes(attributes, ofItemAtPath: directory.path)

            return encryptionContext
        }
        catch let err {
            fatal("failed to init cryptobox: \(err)")
        }
        
        return nil
    }
    
    open func deleteAndCreateNewBox() {
        let fm = FileManager.default
        _ = try? fm.removeItem(at: cryptoboxDirectoryURL)
        encryptionContext = UserClientKeysStore.setupContext(in: cryptoboxDirectoryURL, sharedContainer: sharedContainerURL)!
        internalLastPreKey = nil
    }
    
    /// legacy directories returned with the most currently used first and the oldest last
    static open func legacyDirectories(sharedContainerURL: URL) -> [URL] {
        var legacyOtrDirectory1 : URL {
            let url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            return url.appendingPathComponent(FileManager.keyStoreFolderPrefix)
        }

        var legacyOtrDirectory2 : URL {
            let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            return url.appendingPathComponent(FileManager.keyStoreFolderPrefix)
        }
        
        var legacyOtrDirectory3 : URL {
            return sharedContainerURL.appendingPathComponent(FileManager.keyStoreFolderPrefix)
        }
        
        return [legacyOtrDirectory3, legacyOtrDirectory2, legacyOtrDirectory1]
    }
    
    /// Whether we need to migrate to a new identity (legacy e2ee transition phase)
    open static func needToMigrateIdentity(sharedContainerURL: URL) -> Bool {
        let oldKeyStore = self.legacyDirectories(sharedContainerURL: sharedContainerURL).first{
            FileManager.default.fileExists(atPath: $0.path)
        }
        return oldKeyStore != nil
    }

    open func lastPreKey() throws -> String {
        var error: NSError?
        if internalLastPreKey == nil {
            encryptionContext.perform({ [weak self] (sessionsDirectory) in
                guard let strongSelf = self  else { return }
                do {
                    strongSelf.internalLastPreKey = try sessionsDirectory.generateLastPrekey()
                } catch let anError as NSError {
                    error = anError
                }
                })
        }
        if let error = error {
            throw error
        }
        return internalLastPreKey!
    }
    
    open func generateMoreKeys(_ count: UInt16 = 1, start: UInt16 = 0) throws -> [(id: UInt16, prekey: String)] {
        if count > 0 {
            var error : Error?
            var newPreKeys : [(id: UInt16, prekey: String)] = []
            
            let range = preKeysRange(count, start: start)
            encryptionContext.perform({(sessionsDirectory) in
                do {
                    newPreKeys = try sessionsDirectory.generatePrekeys(range)
                    if newPreKeys.count == 0 {
                        error = UserClientKeyStoreError.canNotGeneratePreKeys
                    }
                }
                catch let anError as NSError {
                    error = anError
                }
            })
            if let error = error {
                throw error
            }
            return newPreKeys
        }
        throw UserClientKeyStoreError.preKeysCountNeedsToBePositive
    }
    
    fileprivate func preKeysRange(_ count: UInt16, start: UInt16) -> CountableRange<UInt16> {
        if start >= UserClientKeysStore.MaxPreKeyID-count {
            return CountableRange(0..<count)
        }
        return CountableRange(start..<(start + count))
    }
    
}
