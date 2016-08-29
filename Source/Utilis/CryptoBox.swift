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

private let zmLog = ZMSLog(tag: "CryptoBox")

extension NSManagedObjectContext {
    
    private static let ZMUserClientKeysStoreKey = "ZMUserClientKeysStore"
    
    /// Returns the cryptobox instance associated with this managed object context
    public var zm_cryptKeyStore : UserClientKeysStore! {
        if !self.zm_isSyncContext {
            fatal("Can't initiliazie crypto box on non-sync context")
        }
        let keyStore: AnyObject? = self.userInfo.objectForKey(NSManagedObjectContext.ZMUserClientKeysStoreKey)
        if let keyStore = keyStore as? UserClientKeysStore {
            return keyStore
        }
        let newKeyStore = UserClientKeysStore()
        self.userInfo.setObject(newKeyStore, forKey: NSManagedObjectContext.ZMUserClientKeysStoreKey)
        return newKeyStore
    }
    
    public func zm_tearDownCryptKeyStore() {
        self.userInfo.removeObjectForKey(NSManagedObjectContext.ZMUserClientKeysStoreKey)
    }

}

public enum UserClientKeyStoreError: ErrorType {
    case CanNotGeneratePreKeys
    case PreKeysCountNeedsToBePositive
}

@objc(UserClientKeysStore)
public class UserClientKeysStore: NSObject {
    
    public static let MaxPreKeyID : UInt16 = UInt16.max-1;
    static private let otrFolderPrefix = "otr"
    public var encryptionContext : EncryptionContext
    private var internalLastPreKey: String?
    
    public override init() {
        encryptionContext = UserClientKeysStore.setupContext()!
    }
    
    static func setupContext() -> EncryptionContext? {
        let encryptionContext : EncryptionContext
        do {
            if self.isPreviousOTRDirectoryPresent {
                do {
                    try NSFileManager.defaultManager().moveItemAtURL(self.legacyOtrDirectory, toURL: self.otrDirectoryURL)
                }
                catch let err {
                    fatal("Cannot move legacy directory: \(err)")
                }
            }
            
            let otrDirectoryURL = UserClientKeysStore.otrDirectory
            encryptionContext = EncryptionContext(path: otrDirectoryURL)
            try otrDirectoryURL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)

            let attributes = [NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication]
            try NSFileManager.defaultManager().setAttributes(attributes, ofItemAtPath: otrDirectoryURL.path!)

            return encryptionContext
        }
        catch let err {
            fatal("failed to init cryptobox: \(err)")
        }
        
        return nil
    }
    
    public func deleteAndCreateNewBox() {
        let fm = NSFileManager.defaultManager()
        _ = try? fm.removeItemAtURL(UserClientKeysStore.otrDirectory)
        internalLastPreKey = nil
        
         encryptionContext = UserClientKeysStore.setupContext()!
        
    }
    
    /// Legacy URL for cryptobox storage (transition phase)
    static public var legacyOtrDirectory : NSURL {
        let url = try? NSFileManager.defaultManager().URLForDirectory(NSSearchPathDirectory.LibraryDirectory, inDomain: NSSearchPathDomainMask.UserDomainMask, appropriateForURL: nil, create: false)
        return url!.URLByAppendingPathComponent(otrFolderPrefix)
    }
    
    /// URL for cryptobox storage (read-only)
    static public var otrDirectoryURL : NSURL {
        var url : NSURL?
        url = try! NSFileManager.defaultManager().URLForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomain: NSSearchPathDomainMask.UserDomainMask, appropriateForURL: nil, create: false)
        url = url!.URLByAppendingPathComponent(otrFolderPrefix)
        
        return url!
    }
    
    /// URL for cryptobox storage
    static public var otrDirectory : NSURL {
        var url : NSURL?
        do {
            url = self.otrDirectoryURL
            try NSFileManager.defaultManager().createDirectoryAtURL(url!, withIntermediateDirectories: true, attributes: nil)
        }
        catch let err as NSError {
            if (url == nil) {
                fatal("Unable to initialize otrDirectory = error: \(err)")
            }
        }
        return url!
    }
    
    /// Legacy URL for cryptobox storage (transition phase)
    private static var isPreviousOTRDirectoryPresent : Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(self.legacyOtrDirectory.path!)
    }
    
    /// Whether we need to migrate to a new identity (legacy e2ee transition phase)
    public static var needToMigrateIdentity : Bool {
        return self.isPreviousOTRDirectoryPresent
    }
    
    /// Remove the old legacy identity folder
    public static func removeOldIdentityFolder() {
        guard let oldIdentityPath = self.legacyOtrDirectory.path
            where NSFileManager.defaultManager().fileExistsAtPath(oldIdentityPath) else {
            return
        }
        
        do {
            try NSFileManager.defaultManager().removeItemAtPath(oldIdentityPath)
        }
        catch let err {
            // if it's still there, we failed to delete. Critical error.
            if self.isPreviousOTRDirectoryPresent {
                fatal("Failed to remove identity from previous folder: \(err)")
            }
        }
    }

    public func lastPreKey() throws -> String {
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
    
    public func generateMoreKeys(count: UInt16 = 1, start: UInt16 = 0) throws -> [(id: UInt16, prekey: String)] {
        if count > 0 {
            var error : ErrorType?
            var newPreKeys : [(id: UInt16, prekey: String)] = []
            
            let range = preKeysRange(count, start: start)
            encryptionContext.perform({(sessionsDirectory) in
                do {
                    newPreKeys = try sessionsDirectory.generatePrekeys(range)
                    if newPreKeys.count == 0 {
                        error = UserClientKeyStoreError.CanNotGeneratePreKeys
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
        throw UserClientKeyStoreError.PreKeysCountNeedsToBePositive
    }
    
    private func preKeysRange(count: UInt16, start: UInt16) -> Range<UInt16> {
        if start >= UserClientKeysStore.MaxPreKeyID-count {
            return Range(0..<count)
        }
        return Range(start..<(start + count))
    }
    
}
