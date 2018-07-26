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
import PINCache
import WireTransport

private let MEGABYTE = UInt(1 * 1000 * 1000)

// MARK: ZMUser
extension ZMUser {
    private func cacheIdentifier(suffix: String?) -> String? {
        guard let userRemoteId = remoteIdentifier?.transportString(), let suffix = suffix else { return nil }
        return (userRemoteId + "-" + suffix)
    }
    
    @objc public func legacyImageCacheKey(for size: ProfileImageSize) -> String? {
        switch size {
        case .preview:
            return cacheIdentifier(suffix: smallProfileRemoteIdentifier?.transportString())
        case .complete:
            return cacheIdentifier(suffix: mediumRemoteIdentifier?.transportString())
        }
    }
    
    @objc public func imageCacheKey(for size: ProfileImageSize) -> String? {
        switch size {
        case .preview:
            return cacheIdentifier(suffix: previewProfileAssetIdentifier)
        case .complete:
            return cacheIdentifier(suffix: completeProfileAssetIdentifier)
        }
    }
    
    fileprivate func resolvedCacheKey(for size: ProfileImageSize) -> String? {
        switch size {
        case .preview:
            return smallProfileImageCacheKey
        case .complete:
            return mediumProfileImageCacheKey
        }
    }
    
    /// Cache keys for all large user images
    fileprivate var largeCacheKeys: [String] {
        return [legacyImageCacheKey(for: .complete), imageCacheKey(for: .complete)].compactMap{ $0 }
    }
    
    /// Cache keys for all small user images
    fileprivate var smallCacheKeys: [String] {
        return [legacyImageCacheKey(for: .preview), imageCacheKey(for: .preview)].compactMap{ $0 }
    }
}

// MARK: NSManagedObjectContext

let NSManagedObjectContextUserImageCacheKey = "zm_userImageCacheKey"
extension NSManagedObjectContext
{
    @objc public var zm_userImageCache : UserImageLocalCache! {
        get {
            return self.userInfo[NSManagedObjectContextUserImageCacheKey] as? UserImageLocalCache
        }
        
        set {
            self.userInfo[NSManagedObjectContextUserImageCacheKey] = newValue
        }
    }
}

// MARK: Cache
@objcMembers open class UserImageLocalCache : NSObject {
    
    fileprivate let log = ZMSLog(tag: "UserImageCache")
    
    /// Cache for large user profile image
    fileprivate let largeUserImageCache : PINCache
    
    /// Cache for small user profile image
    fileprivate let smallUserImageCache : PINCache
    
    
    /// Create UserImageLocalCache
    /// - parameter location: where cache is persisted on disk. Defaults to caches directory if nil.
    public init(location: URL? = nil) {
        
        let largeUserImageCacheName = "largeUserImages"
        let smallUserImageCacheName = "smallUserImages"
        
        if let rootPath = location?.path {
            largeUserImageCache = PINCache(name: largeUserImageCacheName, rootPath: rootPath)
            smallUserImageCache = PINCache(name: smallUserImageCacheName, rootPath: rootPath)
        } else {
            largeUserImageCache = PINCache(name: largeUserImageCacheName)
            smallUserImageCache = PINCache(name: smallUserImageCacheName)
        }
        
        largeUserImageCache.configureLimits(50 * MEGABYTE)
        smallUserImageCache.configureLimits(25 * MEGABYTE)
        
        largeUserImageCache.makeURLSecure()
        smallUserImageCache.makeURLSecure()
        super.init()
    }
    
    /// Stores image in cache and removes legacy copy if it was there, returns true if the data was stored
    private func setImage(inCache cache: PINCache, legacyCacheKey: String?, cacheKey: String?, data: Data) -> Bool {
        let resolvedCacheKey: String?
        if let cacheKey = cacheKey {
            resolvedCacheKey = cacheKey
            if let legacyCacheKey = legacyCacheKey {
                cache.removeObject(forKey: legacyCacheKey)
            }
        } else {
            resolvedCacheKey = legacyCacheKey
        }
        if let resolvedCacheKey = resolvedCacheKey {
            cache.setObject(data as NSCoding, forKey: resolvedCacheKey)
            return true
        }
        return false
    }
    
    /// Removes all images for user
    open func removeAllUserImages(_ user: ZMUser) {
        user.largeCacheKeys.forEach(largeUserImageCache.removeObject)
        user.smallCacheKeys.forEach(smallUserImageCache.removeObject)
    }
    
    open func setUserImage(_ user: ZMUser, imageData: Data, size: ProfileImageSize) {
        let legacyKey = user.legacyImageCacheKey(for: size)
        let key = user.imageCacheKey(for: size)
        switch size {
        case .preview:
            let stored = setImage(inCache: smallUserImageCache, legacyCacheKey: legacyKey, cacheKey: key, data: imageData)
            if stored {
                log.info("Setting [\(user.displayName)] preview image [\(imageData)] cache keys: V3[\(String(describing: key))] V2[\(String(describing: legacyKey))]")
                usersWithChangedSmallImage.append(user.objectID)
            }
        case .complete:
            let stored = setImage(inCache: largeUserImageCache, legacyCacheKey: legacyKey, cacheKey: key, data: imageData)
            if stored {
                log.info("Setting [\(user.displayName)] complete image [\(imageData)] cache keys: V3[\(String(describing: key))] V2[\(String(describing: legacyKey))]")
                usersWithChangedLargeImage.append(user.objectID)
            }
        }
    }
    
    open func userImage(_ user: ZMUser, size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (_ imageData: Data?) -> Void) {
        guard let cacheKey = user.resolvedCacheKey(for: size) else { return completion(nil) }
        
        queue.async {
            switch size {
            case .preview:
                completion(self.smallUserImageCache.object(forKey: cacheKey) as? Data)
            case .complete:
                completion(self.largeUserImageCache.object(forKey: cacheKey) as? Data)
            }
        }
    }
    
    open func userImage(_ user: ZMUser, size: ProfileImageSize) -> Data? {
        guard let cacheKey = user.resolvedCacheKey(for: size) else { return nil }
        let data: Data?
        switch size {
        case .preview:
            data = smallUserImageCache.object(forKey: cacheKey) as? Data
        case .complete:
            data = largeUserImageCache.object(forKey: cacheKey) as? Data
        }
        if let data = data {
            log.info("Getting [\(user.displayName)] \(size == .preview ? "preview" : "complete") image [\(data)] cache key: [\(cacheKey)]")
        }

        return data
    }
    
    open func hasUserImage(_ user: ZMUser, size: ProfileImageSize) -> Bool {
        guard let cacheKey = user.resolvedCacheKey(for: size) else { return false }
        
        switch size {
        case .preview:
            return smallUserImageCache.containsObject(forKey: cacheKey)
        case .complete:
            return largeUserImageCache.containsObject(forKey: cacheKey)
        }
    }
    
    var usersWithChangedSmallImage : [NSManagedObjectID] = []
    var usersWithChangedLargeImage : [NSManagedObjectID] = []

}

public extension UserImageLocalCache {
    func wipeCache() {
        smallUserImageCache.removeAllObjects()
        largeUserImageCache.removeAllObjects()
    }
}
