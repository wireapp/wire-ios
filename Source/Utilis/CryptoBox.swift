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

extension NSManagedObjectContext {
    
    fileprivate static let ZMUserClientKeysStoreKey = "ZMUserClientKeysStore"
    
    @objc(setupUserKeyStoreForDirectory:)
    public func setupUserKeyStore(for directory: URL) -> Void
    {
        if !self.zm_isSyncContext {
            fatal("Can't initiliazie crypto box on non-sync context")
        }
        
        let sharedDirectory = directory.appendingPathComponent(UserClientKeysStore.otrFolderPrefix)

        let newKeyStore = UserClientKeysStore(in: sharedDirectory)
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

public enum UserClientKeyStoreError: Error {
    case canNotGeneratePreKeys
    case preKeysCountNeedsToBePositive
}

@objc(UserClientKeysStore)
open class UserClientKeysStore: NSObject {
    
    open static let MaxPreKeyID : UInt16 = UInt16.max-1;
    static fileprivate let otrFolderPrefix = "otr"
    open var encryptionContext : EncryptionContext
    fileprivate var internalLastPreKey: String?
    public private(set) var cryptoboxDirectoryURL : URL
    
    public init(in directory: URL) {
        cryptoboxDirectoryURL = directory
        encryptionContext = UserClientKeysStore.setupContext(in: directory)!
    }
    
    static func setupContext(in directory: URL) -> EncryptionContext? {
        let encryptionContext : EncryptionContext
        do {
            if UserClientKeysStore.isPreviousOTRDirectoryPresent {
                do {
                    try FileManager.default.moveItem(at: UserClientKeysStore.legacyOtrDirectory, to: directory)
                }
                catch let err {
                    fatal("Cannot move legacy directory: \(err)")
                }
            }
            
            if FileManager.default.fileExists(atPath: UserClientKeysStore.otrDirectoryURL.path) {
                do {
                    try FileManager.default.moveItem(at: UserClientKeysStore.otrDirectoryURL, to: directory)
                }
                catch let err {
                    fatal("Cannot move otr to shared container \(err)")
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
        encryptionContext = UserClientKeysStore.setupContext(in: cryptoboxDirectoryURL)!
        internalLastPreKey = nil
    }
    
    /// Legacy URL for cryptobox storage (transition phase)
    static open var legacyOtrDirectory : URL {
        let url = try? FileManager.default.url(for: FileManager.SearchPathDirectory.libraryDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
        return url!.appendingPathComponent(otrFolderPrefix)
    }
    
    /// URL for cryptobox storage (read-only)
    static open var otrDirectoryURL : URL {
        var url : URL?
        url = try! FileManager.default.url(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
        url = url!.appendingPathComponent(otrFolderPrefix)
        
        return url!
    }
    
    /// URL for cryptobox storage
    static open var otrDirectory : URL {
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
    open static var needToMigrateIdentity : Bool {
        return self.isPreviousOTRDirectoryPresent
    }
    
    /// Remove the old legacy identity folder
    open static func removeOldIdentityFolder() {
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
