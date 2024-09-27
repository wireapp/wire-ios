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
import PINCache
import WireTransport

private let MEGABYTE = UInt(1 * 1000 * 1000)

// MARK: ZMUser

extension ZMUser {
    private func cacheIdentifier(suffix: String?) -> String? {
        guard let userRemoteId = remoteIdentifier?.transportString(), let suffix else { return nil }
        return userRemoteId + "-" + suffix
    }

    @objc
    public func imageCacheKey(for size: ProfileImageSize) -> String? {
        switch size {
        case .preview:
            cacheIdentifier(suffix: previewProfileAssetIdentifier)
        case .complete:
            cacheIdentifier(suffix: completeProfileAssetIdentifier)
        }
    }
}

// MARK: NSManagedObjectContext

let NSManagedObjectContextUserImageCacheKey = "zm_userImageCacheKey"
extension NSManagedObjectContext {
    @objc public var zm_userImageCache: UserImageLocalCache! {
        get {
            userInfo[NSManagedObjectContextUserImageCacheKey] as? UserImageLocalCache
        }

        set {
            userInfo[NSManagedObjectContextUserImageCacheKey] = newValue
        }
    }
}

// MARK: - UserImageLocalCache

@objcMembers
open class UserImageLocalCache: NSObject {
    fileprivate let log = ZMSLog(tag: "UserImageCache")

    /// Cache for large user profile image
    fileprivate let largeUserImageCache: any PINCaching

    /// Cache for small user profile image
    fileprivate let smallUserImageCache: any PINCaching

    /// Create UserImageLocalCache
    /// - parameter location: where cache is persisted on disk. Defaults to caches directory if nil.
    public init(location: URL? = nil) {
        let largeUserImageCacheName = "largeUserImages"
        let smallUserImageCacheName = "smallUserImages"

        let largeUserImageCache: PINDiskCache
        let smallUserImageCache: PINDiskCache

        if let rootPath = location?.path {
            largeUserImageCache = PINDiskCache(name: largeUserImageCacheName, rootPath: rootPath)
            smallUserImageCache = PINDiskCache(name: smallUserImageCacheName, rootPath: rootPath)
        } else {
            largeUserImageCache = PINDiskCache(name: largeUserImageCacheName)
            smallUserImageCache = PINDiskCache(name: smallUserImageCacheName)
        }

        largeUserImageCache.byteLimit = 50 * MEGABYTE
        largeUserImageCache.ageLimit = 60 * 60 // 1 hour
        smallUserImageCache.byteLimit = 25 * MEGABYTE
        smallUserImageCache.ageLimit = 60 * 60 // 1 hour

        largeUserImageCache.makeURLSecure()
        smallUserImageCache.makeURLSecure()

        self.largeUserImageCache = largeUserImageCache
        self.smallUserImageCache = smallUserImageCache

        super.init()
    }

    /// Stores image in cache and returns true if the data was stored
    private func setImage(inCache cache: any PINCaching, cacheKey: String?, data: Data) -> Bool {
        if let resolvedCacheKey = cacheKey {
            cache.setObject(data as NSCoding, forKey: resolvedCacheKey)
            return true
        }
        return false
    }

    /// Removes all images for user
    open func removeAllUserImages(_ user: ZMUser) {
        if let completeKey = user.imageCacheKey(for: .complete) {
            largeUserImageCache.removeObject(forKey: completeKey)
        }

        if let previewKey = user.imageCacheKey(for: .preview) {
            smallUserImageCache.removeObject(forKey: previewKey)
        }
    }

    open func setUserImage(_ user: ZMUser, imageData: Data, size: ProfileImageSize) {
        let key = user.imageCacheKey(for: size)
        switch size {
        case .preview:
            let stored = setImage(inCache: smallUserImageCache, cacheKey: key, data: imageData)
            if stored {
                log
                    .info(
                        "Setting [\(user.name ?? "")] preview image [\(imageData)] cache key: \(String(describing: key))"
                    )
            }

        case .complete:
            let stored = setImage(inCache: largeUserImageCache, cacheKey: key, data: imageData)
            if stored {
                log
                    .info(
                        "Setting [\(user.name ?? "")] complete image [\(imageData)] cache key: \(String(describing: key))"
                    )
            }
        }
    }

    open func userImage(
        _ user: ZMUser,
        size: ProfileImageSize,
        queue: DispatchQueue,
        completion: @escaping (_ imageData: Data?) -> Void
    ) {
        guard let cacheKey = user.imageCacheKey(for: size) else { return completion(nil) }

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
        guard let cacheKey = user.imageCacheKey(for: size) else { return nil }
        let data: Data? = switch size {
        case .preview:
            smallUserImageCache.object(forKey: cacheKey) as? Data
        case .complete:
            largeUserImageCache.object(forKey: cacheKey) as? Data
        }
        if let data {
            log
                .info(
                    "Getting [\(String(describing: user.name))] \(size == .preview ? "preview" : "complete") image [\(data)] cache key: [\(cacheKey)]"
                )
        }

        return data
    }

    open func hasUserImage(_ user: ZMUser, size: ProfileImageSize) -> Bool {
        guard let cacheKey = user.imageCacheKey(for: size) else { return false }

        switch size {
        case .preview:
            return smallUserImageCache.containsObject(forKey: cacheKey)
        case .complete:
            return largeUserImageCache.containsObject(forKey: cacheKey)
        }
    }
}

extension UserImageLocalCache {
    public func wipeCache() {
        smallUserImageCache.removeAllObjects()
        largeUserImageCache.removeAllObjects()
    }
}
