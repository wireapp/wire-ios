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
import MobileCoreServices

@objcMembers
public class V2Asset: NSObject, ZMImageMessageData {
    public var isDownloaded: Bool {
        hasDownloadedFile
    }

    public func fetchImageData(
        with queue: DispatchQueue,
        completionHandler: @escaping ((Data?) -> Void)
    ) {
        let cache = moc.zm_fileAssetCache

        let mediumEncryptedKey = FileAssetCache.cacheKeyForAsset(
            assetClientMessage,
            format: .medium,
            encrypted: true
        )

        let mediumKey = FileAssetCache.cacheKeyForAsset(
            assetClientMessage,
            format: .medium
        )

        let originalKey = FileAssetCache.cacheKeyForAsset(
            assetClientMessage,
            format: .original
        )

        let asset = assetClientMessage.underlyingMessage?.assetData?.uploaded
        let key = asset?.otrKey
        let digest = asset?.sha256

        queue.async {
            guard let cache else {
                completionHandler(nil)
                return
            }

            if let mediumEncryptedKey,
               let key,
               let digest,
               let data = cache.decryptData(
                   key: mediumEncryptedKey,
                   encryptionKey: key,
                   sha256Digest: digest
               ) {
                completionHandler(data)
            } else if let mediumKey,
                      let data = cache.assetData(mediumKey) {
                completionHandler(data)
            } else if let originalKey,
                      let data = cache.assetData(originalKey) {
                completionHandler(data)
            } else {
                completionHandler(nil)
            }
        }
    }

    fileprivate let assetClientMessage: ZMAssetClientMessage
    fileprivate let moc: NSManagedObjectContext

    public init?(with message: ZMAssetClientMessage) {
        guard message.version < 3 else { return nil }
        self.assetClientMessage = message

        guard let managedObjectContext = message.managedObjectContext else { return nil }
        self.moc = managedObjectContext
    }

    public var imageMessageData: ZMImageMessageData? {
        guard assetClientMessage.mediumGenericMessage != nil || assetClientMessage.previewGenericMessage != nil
        else { return nil }

        return self
    }

    // MARK: - ZMImageMessageData

    private var mediumData: Data? {
        guard
            let asset = assetClientMessage.mediumGenericMessage?.imageAssetData,
            asset.width > 0,
            asset.size > 0,
            let cache = moc.zm_fileAssetCache
        else {
            return nil
        }

        if let data = cache.decryptedMediumImageData(
            for: assetClientMessage,
            encryptionKey: asset.otrKey,
            sha256Digest: asset.sha256
        ) {
            return data
        } else if let data = cache.mediumImageData(for: assetClientMessage) {
            return data
        } else {
            return nil
        }
    }

    public var imageData: Data? {
        guard let cache = moc.zm_fileAssetCache else {
            return nil
        }

        return mediumData ?? cache.originalImageData(for: assetClientMessage)
    }

    public var imageDataIdentifier: String? {
        FileAssetCache.cacheKeyForAsset(assetClientMessage, format: .medium)
    }

    public var imagePreviewDataIdentifier: String? {
        FileAssetCache.cacheKeyForAsset(assetClientMessage, format: .preview)
    }

    public var previewData: Data? {
        if assetClientMessage.hasDownloadedPreview {
            guard let cache = moc.zm_fileAssetCache else {
                return nil
            }

            // File preview data
            return cache.originalImageData(for: assetClientMessage) ?? cache.mediumImageData(for: assetClientMessage)
        }

        return nil
    }

    public var isAnimatedGIF: Bool {
        guard let mimeType = assetClientMessage.mediumGenericMessage?.imageAssetData?.mimeType else {
            return false
        }
        return UTIHelper.conformsToGifType(mime: mimeType)
    }

    public var imageType: String? {
        assetClientMessage.mediumGenericMessage?.imageAssetData?.mimeType
    }

    public var originalSize: CGSize {
        guard let asset = assetClientMessage.mediumGenericMessage?.imageAssetData else { return .zero }
        let size = CGSize(width: Int(asset.originalWidth), height: Int(asset.originalHeight))

        if size != .zero {
            return size
        }

        return assetClientMessage.preprocessedSize
    }
}

extension V2Asset: AssetProxyType {
    private var hasImageData: Bool {
        guard let cache = moc.zm_fileAssetCache else {
            return false
        }

        return cache.hasEncryptedMediumImageData(for: assetClientMessage)
            || cache.hasMediumImageData(for: assetClientMessage)
            || cache.hasOriginalImageData(for: assetClientMessage)
    }

    public var hasDownloadedPreview: Bool {
        assetClientMessage.fileMessageData != nil && hasImageData
    }

    public var hasDownloadedFile: Bool {
        if assetClientMessage.imageMessageData != nil {
            return hasImageData
        } else {
            guard let cache = moc.zm_fileAssetCache else {
                return false
            }

            return cache.hasFileData(for: assetClientMessage)
        }
    }

    public var fileURL: URL? {
        guard let cache = moc.zm_fileAssetCache else {
            return nil
        }

        if cache.hasEncryptedFileData(for: assetClientMessage) {
            guard let asset = assetClientMessage.underlyingMessage?.assetData?.uploaded else {
                return nil
            }

            return cache.temporaryURLForDecryptedFile(
                for: assetClientMessage,
                encryptionKey: asset.otrKey,
                sha256Digest: asset.sha256
            )
        } else if cache.hasOriginalFileData(for: assetClientMessage) {
            return cache.accessAssetURL(assetClientMessage)
        } else {
            return nil
        }
    }

    public func requestFileDownload() {
        guard assetClientMessage.fileMessageData != nil || assetClientMessage.imageMessageData != nil else { return }
        guard !assetClientMessage.objectID.isTemporaryID, let moc = moc.zm_userInterface else { return }

        if assetClientMessage.imageMessageData != nil {
            NotificationInContext(
                name: ZMAssetClientMessage.imageDownloadNotificationName,
                context: moc.notificationContext,
                object: assetClientMessage.objectID
            ).post()
        } else {
            NotificationInContext(
                name: ZMAssetClientMessage.assetDownloadNotificationName,
                context: moc.notificationContext,
                object: assetClientMessage.objectID
            ).post()
        }
    }

    public func requestPreviewDownload() {
        guard !assetClientMessage.objectID.isTemporaryID, let moc = moc.zm_userInterface else { return }
        if assetClientMessage.underlyingMessage?.assetData?.hasPreview == true {
            NotificationInContext(
                name: ZMAssetClientMessage.imageDownloadNotificationName,
                context: moc.notificationContext,
                object: assetClientMessage.objectID
            ).post()
        }
    }
}
