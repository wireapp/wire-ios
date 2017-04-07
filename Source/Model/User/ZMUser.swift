//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

@objc public enum ProfileImageSize: Int {
    case preview
    case complete
    
    public var imageFormat: ZMImageFormat {
        switch self {
        case .preview:
            return .profile
        case .complete:
            return .medium
        }
    }

    public init?(stringValue: String) {
        switch stringValue {
        case ProfileImageSize.preview.stringValue: self = .preview
        case ProfileImageSize.complete.stringValue: self = .complete
        default: return nil
        }
    }

    var stringValue: String {
        switch self {
        case .preview: return "preview"
        case .complete: return "complete"
        }
    }
    
    public static var allSizes: [ProfileImageSize] {
        return [.preview, .complete]
    }
    
    internal var userKeyPath: String {
        switch self {
        case .preview:
            return #keyPath(ZMUser.imageSmallProfileData)
        case .complete:
            return #keyPath(ZMUser.imageMediumData)
        }
    }
}

extension ProfileImageSize: CustomDebugStringConvertible {
     public var debugDescription: String {
        switch self {
        case .preview:
            return "ProfileImageSize.preview"
        case .complete:
            return "ProfileImageSize.complete"
        }
    }
}

extension ZMUser {
    static let previewProfileAssetIdentifierKey = #keyPath(ZMUser.previewProfileAssetIdentifier)
    static let completeProfileAssetIdentifierKey = #keyPath(ZMUser.completeProfileAssetIdentifier)
    
    public static let previewAssetFetchNotification = Notification.Name(rawValue:"ZMRequestUserProfilePreviewAssetV3NotificationName")
    public static let completeAssetFetchNotification = Notification.Name(rawValue:"ZMRequestUserProfileCompleteAssetV3NotificationName")

    @NSManaged public var previewProfileAssetIdentifier: String?
    @NSManaged public var completeProfileAssetIdentifier: String?
    
    
    @objc(setImageData:size:)
    public func setImage(data: Data?, size: ProfileImageSize) {
        let key = size.userKeyPath
        willChangeValue(forKey: key)
        if isSelfUser {
            setPrimitiveValue(data, forKey: key)
            if originalProfileImageData != nil {
                setLocallyModifiedKeys([key])
            }
        } else {
            guard let imageData = data else {
                managedObjectContext?.zm_userImageCache?.removeAllUserImages(self)
                return
            }
            managedObjectContext?.zm_userImageCache?.setUserImage(self, imageData: imageData, size: size)
        }
        didChangeValue(forKey: key)
        managedObjectContext?.saveOrRollback()
    }
    
    @objc(imageDataforSize:)
    public func imageData(for size: ProfileImageSize) -> Data? {
        if isSelfUser {
            willAccessValue(forKey: size.userKeyPath)
            let value = primitiveValue(forKey: size.userKeyPath) as? Data
            didAccessValue(forKey: size.userKeyPath)
            return value
        } else {
            return managedObjectContext?.zm_userImageCache?.userImage(self, size: size)
        }
    }
    
    public static var previewImageDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", ZMUser.previewProfileAssetIdentifierKey)
        let notCached = NSPredicate() { (user, _) -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.imageSmallProfileData == nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists, notCached])
    }
    
    public static var completeImageDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", ZMUser.completeProfileAssetIdentifierKey)
        let notCached = NSPredicate() { (user, _) -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.imageMediumData == nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists, notCached])
    }
    
    public func updateAndSyncProfileAssetIdentifiers(previewIdentifier: String, completeIdentifier: String) {
        guard isSelfUser else { return }
        previewProfileAssetIdentifier = previewIdentifier
        completeProfileAssetIdentifier = completeIdentifier
        setLocallyModifiedKeys([ZMUser.previewProfileAssetIdentifierKey, ZMUser.completeProfileAssetIdentifierKey])
    }
    
    @objc public func updateAssetData(with assets: NSArray?, hasLegacyImages: Bool, authoritative: Bool) {
        guard !hasLocalModifications(forKeys: [ZMUser.previewProfileAssetIdentifierKey, ZMUser.completeProfileAssetIdentifierKey]) else { return }
        guard let assets = assets as? [[String : String]], !assets.isEmpty else {
            if authoritative {
                previewProfileAssetIdentifier = nil
                completeProfileAssetIdentifier = nil
                // Deleting image data only if we don't have V2 profile image as well
                if !hasLegacyImages {
                    imageSmallProfileData = nil
                    imageMediumData = nil
                }
            }
            return
        }
        for data in assets {
            if let size = data["size"].flatMap(ProfileImageSize.init), let key = data["key"] {
                switch size {
                case .preview:
                    if key != previewProfileAssetIdentifier {
                        previewProfileAssetIdentifier = key
                        imageSmallProfileData = nil
                    }
                case .complete:
                    if key != completeProfileAssetIdentifier {
                        completeProfileAssetIdentifier = key
                        imageMediumData = nil
                    }
                }
            }
        }
    }
    
    @objc public func requestPreviewAsset() {
        NotificationCenter.default.post(name: ZMUser.previewAssetFetchNotification, object: objectID)
    }
    
    @objc public func requestCompleteAsset() {
        NotificationCenter.default.post(name: ZMUser.completeAssetFetchNotification, object: objectID)
    }
}
