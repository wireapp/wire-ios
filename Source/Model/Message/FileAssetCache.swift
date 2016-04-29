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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation

private let NSManagedObjectContextFileAssetCacheKey = "zm_fileAssetCache"
private var zmLog = ZMSLog(tag: "assets")


extension NSManagedObjectContext
{
    public var zm_fileAssetCache : FileAssetCache {
        get {
            return self.userInfo[NSManagedObjectContextFileAssetCacheKey] as! FileAssetCache
        }
        
        set {
            self.userInfo[NSManagedObjectContextFileAssetCacheKey] = newValue
        }
    }
}

/// A file cache
/// This class is NOT thread safe. However, the only problematic operation is deleting.
/// Any thread can read objects that are never deleted without any problem.
/// Objects purged from the cache folder by the OS are not a problem as the
/// OS will terminate the app before purging the cache.
private struct FileCache : Cache {
    
    /// URL of the cache
    static let cacheFolderURL : NSURL = {
        guard let cacheURL = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first else {
            fatal("Can't create caches directory")
        }
        return cacheURL
    }()
    
    init(name: String) {
        
        // create and set attributes
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(self.dynamicType.cacheFolderURL, withIntermediateDirectories:true, attributes:[NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication])
        }
        catch {
            fatal("Can't create cache directory: \(self.dynamicType.cacheFolderURL)")
        }
        
        do {
            try self.dynamicType.cacheFolderURL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
        }
        catch {
            fatal("Can not exclude cache directory from backup: \(self.dynamicType.cacheFolderURL)")
        }
    }
    
    func assetData(key: String) -> NSData? {
        let url = URLForKey(key)
        let data: NSData?
        do {
            data = try NSData(contentsOfURL: url, options: .DataReadingMappedIfSafe)
        }
        catch let error as NSError {
            if error.code != NSFileReadNoSuchFileError {
                zmLog.error("\(error)")
            }
            data = nil
        }
        return data
    }
    
    func storeAssetData(data: NSData, key: String) {
        let url = URLForKey(key)
        NSFileManager.defaultManager().createFileAtPath(url.path!, contents: data, attributes: [NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication])
        do {
            try url.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
        } catch {
            _ = try? NSFileManager.defaultManager().removeItemAtURL(url)
            fatal("Failed to exclude file from backup \(url) \(error)")
        }
    }
    
    func storeAssetFromURL(url: NSURL, key: String) {
        guard url.scheme == NSURLFileScheme else { fatal("Can't save remote URL to cache: \(url)") }
        let finalURL = URLForKey(key)
        do {
            try NSFileManager.defaultManager().copyItemAtURL(url, toURL: finalURL)
            try NSFileManager.defaultManager().setAttributes([NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication], ofItemAtPath: finalURL.path!)
            try finalURL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
        } catch {
            _ = try? NSFileManager.defaultManager().removeItemAtURL(finalURL)
            fatal("Failed to copy from \(url) to \(finalURL), \(error)")
        }
        
    }
    
    func deleteAssetData(key: String) {
        let url = URLForKey(key)
        do {
            try NSFileManager.defaultManager().removeItemAtURL(url)
        }
        catch let error as NSError {
            if error.domain != NSCocoaErrorDomain || error.code != NSFileNoSuchFileError {
                zmLog.error("Can't delete file \(url.pathComponents!.last!): \(error)")
            }
        }
    }
    
    func assetURL(key: String) -> NSURL? {
        let url = URLForKey(key)
        let ptr : NSErrorPointer = nil
        if url.checkResourceIsReachableAndReturnError(ptr) {
            return url
        }
        return nil
    }
    
    /// Returns the expected URL of a cache entry
    private func URLForKey(key: String) -> NSURL {
        guard key != "." && key != ".." else { fatal("Can't use \(key) as cache key") }
        var safeKey = key
        for c in ":\\/%\"".characters { // see https://en.wikipedia.org/wiki/Filename#Reserved_characters_and_words
            safeKey = safeKey.stringByReplacingOccurrencesOfString("\(c)", withString: "_")
        }
        return self.dynamicType.cacheFolderURL.URLByAppendingPathComponent(safeKey)
    }

    /// Deletes all existing caches. After calling this method, existing caches should not be used anymore.
    /// This is intended for testing
    static func wipeCaches() {
        _ = try? NSFileManager.defaultManager().removeItemAtURL(self.cacheFolderURL)
    }
}

// MARK: - File asset cache
/// A file cache
/// This class is NOT thread safe. However, the only problematic operation is deleting.
/// Any thread can read objects that are never deleted without any problem.
/// Objects purged from the cache folder by the OS are not a problem as the
/// OS will terminate the app before purging the cache.
public class FileAssetCache : NSObject {
    
    let cache : Cache
    
    /// Creates an asset cache
    public override init() {
        
        self.cache = FileCache(name: "files")
    }
    
    /// Returns the asset data for a given message. This will probably cause I/O
    public func assetData(messageID: NSUUID, fileName: String, encrypted: Bool) -> NSData? {
        return self.cache.assetData(self.dynamicType.cacheKeyForAsset(messageID, fileName: fileName, encrypted: encrypted))
    }
    
    /// Returns the asset URL for a given message
    public func accessAssetURL(messageID: NSUUID, fileName: String) -> NSURL? {
        return self.cache.assetURL(self.dynamicType.cacheKeyForAsset(messageID, fileName: fileName))
    }
    
    /// Returns the asset URL for a given message
    public func accessRequestURL(messageID: NSUUID) -> NSURL? {
        return cache.assetURL(self.dynamicType.cacheKeyForAsset(messageID, fileName: "", request: true))
    }
    
    /// Sets the asset data for a given message. This will cause I/O
    public func storeAssetData(messageID: NSUUID, fileName: String, encrypted: Bool, data: NSData) {
        self.cache.storeAssetData(data, key: self.dynamicType.cacheKeyForAsset(messageID, fileName: fileName, encrypted: encrypted))
    }
    
    /// Sets the request data for a given message and returns the asset url. This will cause I/O
    public func storeRequestData(messageID: NSUUID, data: NSData) -> NSURL? {
        let key = self.dynamicType.cacheKeyForAsset(messageID, fileName: "", request: true)
        cache.storeAssetData(data, key: key)
        return accessRequestURL(messageID)
    }
    
    /// Deletes the request data for a given message. This will cause I/O
    public func deleteRequestData(messageID: NSUUID) {
        let key = self.dynamicType.cacheKeyForAsset(messageID, fileName: "", request: true)
        cache.deleteAssetData(key)
    }
    
    /// Deletes the data for a given message. This will cause I/O
    public func deleteAssetData(messageID: NSUUID, fileName: String, encrypted: Bool) {
        self.cache.deleteAssetData(self.dynamicType.cacheKeyForAsset(messageID, fileName: fileName, encrypted: encrypted))
    }
    
    /// Returns the cache key for an asset
    static func cacheKeyForAsset(messageID: NSUUID, fileName: String, encrypted: Bool = false, request: Bool = false) -> String {
        precondition(!(request && encrypted))
        
        if (encrypted) {
            return "\(messageID.transportString()).enc"
        }
        else if (request) {
            return "\(messageID.transportString())_request"
        }
        else {
            return "\(messageID.transportString())_\(fileName)"
        }
    }
    
}

// MARK: - Testing
public extension FileAssetCache {
    /// Deletes all existing caches. After calling this method, existing caches should not be used anymore.
    /// This is intended for testing
    static func wipeCaches() {
        FileCache.wipeCaches()
    }
}

