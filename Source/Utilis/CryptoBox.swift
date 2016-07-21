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

}

public enum UserClientKeyStoreError: ErrorType {
    case CanNotGeneratePreKeys
    case PreKeysCountNeedsToBePositive
}

@objc(UserClientKeysStore)
public class UserClientKeysStore: NSObject {
    
    static private let otrFolderPrefix = "otr"
    public var box : CBCryptoBox
    private var internalLastPreKey: CBPreKey?
    
    public override init() {
        box = UserClientKeysStore.setupBox()!
    }
    
    static func setupBox() -> CBCryptoBox? {
        let box : CBCryptoBox
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
            box = try CBCryptoBox(pathURL: otrDirectoryURL)
            try otrDirectoryURL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)

            let attributes = [NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication]
            try NSFileManager.defaultManager().setAttributes(attributes, ofItemAtPath: otrDirectoryURL.path!)

            return box
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
        
        box = UserClientKeysStore.setupBox()!
        
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

    public func lastPreKey() throws -> CBPreKey {
        if internalLastPreKey == nil {
            do {
                internalLastPreKey = try box.lastPreKey()
            }
            catch let error as NSError {
                throw error
            }
        }
        return internalLastPreKey!
    }
    
    public func generateMoreKeys(count: UInt = 1, start: UInt = 0) throws -> (keys: [CBPreKey], minIndex: UInt, maxIndex: UInt) {
        if count > 0 {
            let range = preKeysRange(count, start: start)
            do {
                let newPreKeys = try box.generatePreKeys(range) as? [CBPreKey]
                if newPreKeys?.count == 0 {
                    throw UserClientKeyStoreError.CanNotGeneratePreKeys
                }
                let preKeysRangeMax = UInt(NSMaxRange(range))
                return (keys: newPreKeys!, minIndex: UInt(range.location), maxIndex: preKeysRangeMax)
            }
            catch let error as NSError {
                throw error
            }
        }
        throw UserClientKeyStoreError.PreKeysCountNeedsToBePositive
    }
    
    private func preKeysRange(count: UInt, start: UInt) -> NSRange {
        var preKeysRange = NSMakeRange(Int(start), Int(count))
        if NSMaxRange(preKeysRange) >= Int(CBMaxPreKeyID) {
            preKeysRange = NSMakeRange(0, Int(count))
        }
        return preKeysRange
    }
    
    deinit {
        self.box.close()
    }
    
}