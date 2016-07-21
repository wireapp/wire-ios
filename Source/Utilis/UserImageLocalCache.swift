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
    private var largeImageCacheKey : String? {
        if let mediumImageRemoteId = self.mediumRemoteIdentifier,
            let userRemoteId = self.remoteIdentifier
        {
            return (userRemoteId.transportString())! + "-" + mediumImageRemoteId.transportString()
        }
        return .None
    }
    
    /// The identifier to use for the small profile image
    private var smallImageCacheKey : String? {
        if let smallImageRemoteId = self.smallProfileRemoteIdentifier?.transportString(),
            let userRemoteId = self.remoteIdentifier?.transportString()
        {
            return userRemoteId + "-" + smallImageRemoteId
        }
        return .None
    }
}

// MARK: NSManagedObjectContext

let NSManagedObjectContextUserImageCacheKey = "zm_userImageCacheKey"

extension NSManagedObjectContext
{
    public var zm_userImageCache : UserImageLocalCache {
        get {
            return self.userInfo[NSManagedObjectContextUserImageCacheKey] as! UserImageLocalCache
        }
        
        set {
            self.userInfo[NSManagedObjectContextUserImageCacheKey] = newValue
        }
    }
}

// MARK: Cache
@objc public class UserImageLocalCache : NSObject {
    
    /// Cache for large user profile image
    private let largeUserImageCache : PINCache
    
    /// Cache for small user profile image
    private let smallUserImageCache : PINCache
    
    public override init() {
        largeUserImageCache = PINCache(name: "largeUserImages")
        largeUserImageCache.configureLimits(50 * MEGABYTE)
        smallUserImageCache = PINCache(name: "smallUserImages")
        smallUserImageCache.configureLimits(25 * MEGABYTE)
        
        largeUserImageCache.makeURLSecure()
        smallUserImageCache.makeURLSecure()
        super.init()
    }
    
    /// Large image for user
    public func largeUserImage(user: ZMUser) -> NSData? {
        if let largeId = user.largeImageCacheKey
        {
            return self.largeUserImageCache.objectForKey(largeId) as? NSData
        }
        return .None
    }
    
    /// Sets the large user image for a user
    public func setLargeUserImage(user: ZMUser, imageData: NSData) {
        if let largeId = user.largeImageCacheKey {
            self.largeUserImageCache.setObject(imageData, forKey: largeId)
        }
    }
    
    /// Small image for user
    public func smallUserImage(user: ZMUser) -> NSData? {
        if let smallId = user.smallImageCacheKey
        {
            return self.smallUserImageCache.objectForKey(smallId) as? NSData
        }
        return .None
    }
    
    /// Sets the small user image for a user
    public func setSmallUserImage(user: ZMUser, imageData: NSData) {
        if let smallId = user.smallImageCacheKey {
            self.smallUserImageCache.setObject(imageData, forKey: smallId)
        }
    }
}

public extension UserImageLocalCache {
    func wipeCache() {
        smallUserImageCache.removeAllObjects()
        largeUserImageCache.removeAllObjects()
    }
}
