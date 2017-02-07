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
import ZMTransport

private let MEGABYTE = UInt(1 * 1000 * 1000)

// MARK: ZMUser
extension ZMUser {
    
    /// The identifier to use for the large profile image
    fileprivate var largeImageCacheKey : String? {
        if let mediumImageRemoteId = self.mediumRemoteIdentifier?.transportString(),
            let userRemoteId = self.remoteIdentifier?.transportString()
        {
            return (userRemoteId + "-" + mediumImageRemoteId)
        }
        return .none
    }
    
    /// The identifier to use for the small profile image
    fileprivate var smallImageCacheKey : String? {
        if let smallImageRemoteId = self.smallProfileRemoteIdentifier?.transportString(),
            let userRemoteId = self.remoteIdentifier?.transportString()
        {
            return userRemoteId + "-" + smallImageRemoteId
        }
        return .none
    }
}

// MARK: NSManagedObjectContext

let NSManagedObjectContextUserImageCacheKey = "zm_userImageCacheKey"

extension NSManagedObjectContext
{
    public var zm_userImageCache : UserImageLocalCache! {
        get {
            return self.userInfo[NSManagedObjectContextUserImageCacheKey] as? UserImageLocalCache
        }
        
        set {
            self.userInfo[NSManagedObjectContextUserImageCacheKey] = newValue
        }
    }
}

// MARK: Cache
@objc open class UserImageLocalCache : NSObject {
    
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
    
    /// Removes all images for user
    open func removeAllUserImages(_ user: ZMUser) {
        if let largeId = user.largeImageCacheKey {
            self.largeUserImageCache.removeObject(forKey: largeId)
        }
        if let smallId = user.smallImageCacheKey {
            self.smallUserImageCache.removeObject(forKey: smallId)
        }
    }
    
    /// Large image for user
    open func largeUserImage(_ user: ZMUser) -> Data? {
        if let largeId = user.largeImageCacheKey
        {
            return self.largeUserImageCache.object(forKey: largeId) as? Data
        }
        return .none
    }
    
    /// Sets the large user image for a user
    open func setLargeUserImage(_ user: ZMUser, imageData: Data) {
        if let largeId = user.largeImageCacheKey {
            self.largeUserImageCache.setObject(imageData as NSCoding, forKey: largeId)
            usersWithChangedLargeImage.append(user.objectID)
        }
    }
    
    /// Small image for user
    open func smallUserImage(_ user: ZMUser) -> Data? {
        if let smallId = user.smallImageCacheKey
        {
            return self.smallUserImageCache.object(forKey: smallId) as? Data
        }
        return .none
    }
    
    /// Sets the small user image for a user
    open func setSmallUserImage(_ user: ZMUser, imageData: Data) {
        if let smallId = user.smallImageCacheKey {
            self.smallUserImageCache.setObject(imageData as NSCoding, forKey: smallId)
            usersWithChangedSmallImage.append(user.objectID)
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
