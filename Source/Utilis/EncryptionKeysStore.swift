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
import Cryptobox


public enum UserClientKeyStoreError: Error {
    case canNotGeneratePreKeys
    case preKeysCountNeedsToBePositive
}

public class EncryptionKeysStore {
    
    // Max prekey ID that can be generated
    public static let MaxPreKeyID : UInt16 = UInt16.max-1;
    
    // folder name for key store
    static fileprivate let otrFolderPrefix = "otr"
    
    private(set) public var encryptionContext : EncryptionContext
    
    fileprivate weak var managedObjectContext : NSManagedObjectContext?
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        encryptionContext = EncryptionKeysStore.setupContext()!
    }
    
    static func setupContext() -> EncryptionContext? {
        let encryptionContext : EncryptionContext
        do {
            if self.isPreviousOTRDirectoryPresent {
                do {
                    try FileManager.default.moveItem(at: self.legacyOtrDirectory, to: self.otrDirectoryURL)
                }
                catch let err {
                    fatal("Cannot move legacy directory: \(err)")
                }
            }
            
            let otrDirectoryURL = EncryptionKeysStore.otrDirectory
            encryptionContext = EncryptionContext(path: otrDirectoryURL)
            try (otrDirectoryURL as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)

            let attributes = [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            try FileManager.default.setAttributes(attributes, ofItemAtPath: otrDirectoryURL.path)

            return encryptionContext
        }
        catch let err {
            fatal("failed to init cryptobox: \(err)")
        }
        
        return nil
    }
    
    public func deleteAndCreateNewBox() {
        let fm = FileManager.default
        _ = try? fm.removeItem(at: EncryptionKeysStore.otrDirectory)
        self.managedObjectContext?.lastGeneratedPrekey = nil
        
         encryptionContext = EncryptionKeysStore.setupContext()!
        
    }
    
}

// MARK: - Directory management 
extension EncryptionKeysStore {

    /// Legacy URL for cryptobox storage (transition phase)
    static public var legacyOtrDirectory : URL {
        let url = try? FileManager.default.url(for: FileManager.SearchPathDirectory.libraryDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
        return url!.appendingPathComponent(otrFolderPrefix)
    }
    
    /// URL for cryptobox storage (read-only)
    static public var otrDirectoryURL : URL {
        var url : URL?
        url = try! FileManager.default.url(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
        url = url!.appendingPathComponent(otrFolderPrefix)
        
        return url!
    }
    
    /// URL for cryptobox storage
    static public var otrDirectory : URL {
        var url : URL?
        do {
            url = self.otrDirectoryURL
            try FileManager.default.createDirectory(at: url!, withIntermediateDirectories: true, attributes: nil)
        }
        catch let err as NSError {
            if (url == nil) {
                fatal("Unable to initialize otrDirectory = error: \(err)")
            }
        }
        return url!
    }
    
    /// Legacy URL for cryptobox storage (transition phase)
    fileprivate static var isPreviousOTRDirectoryPresent : Bool {
        return FileManager.default.fileExists(atPath: self.legacyOtrDirectory.path)
    }
    
    /// Whether we need to migrate to a new identity (legacy e2ee transition phase)
    public static var needToMigrateIdentity : Bool {
        return self.isPreviousOTRDirectoryPresent
    }
    
    /// Remove the old legacy identity folder
    public static func removeOldIdentityFolder() {
        let oldIdentityPath = self.legacyOtrDirectory.path
        guard FileManager.default.fileExists(atPath: oldIdentityPath) else {
            return
        }
        
        do {
            try FileManager.default.removeItem(atPath: oldIdentityPath)
        }
        catch let err {
            // if it's still there, we failed to delete. Critical error.
            if self.isPreviousOTRDirectoryPresent {
                fatal("Failed to remove identity from previous folder: \(err)")
            }
        }
    }
}

// MARK: - Prekey generation
extension EncryptionKeysStore : KeyStore {
    
    public func lastPreKey() throws -> String {
        var error: NSError?
        if self.managedObjectContext?.lastGeneratedPrekey == nil {
            encryptionContext.perform({ [weak self] (sessionsDirectory) in
                guard let strongSelf = self  else { return }
                do {
                    strongSelf.managedObjectContext?.lastGeneratedPrekey = try sessionsDirectory.generateLastPrekey()
                } catch let anError as NSError {
                    error = anError
                }
                })
        }
        if let error = error {
            throw error
        }
        return self.managedObjectContext!.lastGeneratedPrekey!
    }
    
    /// Generates prekeys in a range. This should not be called more than once
    /// for a given range, or the previously generated prekeys will be invalidated.
    public func generatePreKeys(_ count: UInt16, start: UInt16) throws -> [(id: UInt16, prekey: String)] {
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
        if start >= EncryptionKeysStore.MaxPreKeyID-count {
            return CountableRange(0..<count)
        }
        return CountableRange(start..<(start + count))
    }
    
}

// MARK: - Context singleton
extension NSManagedObjectContext {
    
    fileprivate static let encryptionKeysStoreKey = "ZMUserClientKeysStore" as NSString
    
    private static let lastPrekeyKey = "ZMUserClientKeyStore_LastPrekey" as NSString
    
    /// Returns the cryptobox instance associated with this managed object context
    public var zm_cryptKeyStore : KeyStore! {
        if !self.zm_isSyncContext {
            fatal("Can't initiliazie crypto box on non-sync context")
        }
        let keyStore = self.userInfo.object(forKey: NSManagedObjectContext.encryptionKeysStoreKey)
        if let keyStore = keyStore as? KeyStore {
            return keyStore
        }
        let newKeyStore = EncryptionKeysStore(managedObjectContext: self)
        self.userInfo.setObject(newKeyStore, forKey: NSManagedObjectContext.encryptionKeysStoreKey)
        return newKeyStore
    }
    
    /// this method is intended for testing. It will inject a custom key store in the context
    public func test_injectCryptKeyStore(_ keyStore: KeyStore) {
        self.userInfo.setObject(keyStore, forKey: NSManagedObjectContext.encryptionKeysStoreKey)
    }
    
    public func zm_tearDownCryptKeyStore() {
        self.userInfo.removeObject(forKey: NSManagedObjectContext.encryptionKeysStoreKey)
    }
    
    // Last generated prekey
    fileprivate var lastGeneratedPrekey : String? {
        
        get {
            return self.userInfo.object(forKey: NSManagedObjectContext.lastPrekeyKey) as? String
        }
        
        set {
            if let value = newValue {
                self.userInfo.setObject(value, forKey: NSManagedObjectContext.lastPrekeyKey)
            } else {
                self.userInfo.removeObject(forKey: NSManagedObjectContext.lastPrekeyKey)
            }
        }
    }
}
