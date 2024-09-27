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

private let zmLog = ZMSLog(tag: "AssetV3")

// MARK: - AssetProxyType

/// This protocol is used to hide the implementation of the different
/// asset types (v2 image & file vs. v3 file) from ZMAssetClientMessage.
/// It only includes methods in which these two versions differentiate.
@objc
public protocol AssetProxyType {
    var hasDownloadedFile: Bool { get }
    var hasDownloadedPreview: Bool { get }

    var imageMessageData: ZMImageMessageData? { get }
    var fileURL: URL? { get }

    var imagePreviewDataIdentifier: String? { get }

    func requestFileDownload()
    func requestPreviewDownload()

    @objc(fetchImageDataWithQueue:completionHandler:)
    func fetchImageData(with queue: DispatchQueue!, completionHandler: ((Data?) -> Void)!)
}

// MARK: - V3Asset

@objcMembers
public class V3Asset: NSObject, ZMImageMessageData {
    // MARK: Lifecycle

    public init?(with message: ZMAssetClientMessage) {
        guard message.version == 3 else { return nil }
        self.assetClientMessage = message
        self.moc = message.managedObjectContext!
    }

    // MARK: Public

    public var isDownloaded: Bool {
        hasDownloadedFile
    }

    public var imageMessageData: ZMImageMessageData? {
        guard isImage else { return nil }
        return self
    }

    public var imageData: Data? {
        guard
            assetClientMessage.fileMessageData != nil,
            isImage,
            let cache = moc.zm_fileAssetCache
        else {
            return nil
        }

        if let asset = assetClientMessage.underlyingMessage?.assetData?.uploaded,
           let data = cache.decryptedMediumImageData(
               for: assetClientMessage,
               encryptionKey: asset.otrKey,
               sha256Digest: asset.sha256
           ) {
            return data
        } else if let data = cache.mediumImageData(for: assetClientMessage) {
            return data
        } else if let data = cache.originalImageData(for: assetClientMessage) {
            return data
        } else {
            return nil
        }
    }

    public var imageDataIdentifier: String? {
        FileAssetCache.cacheKeyForAsset(assetClientMessage, format: .medium)
    }

    public var imagePreviewDataIdentifier: String? {
        FileAssetCache.cacheKeyForAsset(assetClientMessage, format: .preview)
    }

    public var isAnimatedGIF: Bool {
        guard let mimeType = assetClientMessage.underlyingMessage?.assetData?.original.mimeType else {
            return false
        }
        return UTIHelper.conformsToGifType(mime: mimeType)
    }

    public var imageType: String? {
        guard isImage else { return nil }
        return assetClientMessage.underlyingMessage?.assetData?.original.mimeType
    }

    public var originalSize: CGSize {
        guard assetClientMessage.fileMessageData != nil, isImage else { return .zero }
        guard let asset = assetClientMessage.underlyingMessage?.assetData else { return .zero }
        let size = CGSize(width: Int(asset.original.image.width), height: Int(asset.original.image.height))

        if size != .zero {
            return size
        }

        return assetClientMessage.preprocessedSize
    }

    @objc(fetchImageDataWithQueue:completionHandler:)
    public func fetchImageData(with queue: DispatchQueue, completionHandler: @escaping ((Data?) -> Void)) {
        let cache = moc.zm_fileAssetCache

        let mediumKey = FileAssetCache.cacheKeyForAsset(
            assetClientMessage,
            format: .medium,
            encrypted: true
        )

        // Just in case we're trying to access an asset that in not stored encrypted.
        let fallbackKey = FileAssetCache.cacheKeyForAsset(
            assetClientMessage,
            format: .medium,
            encrypted: false
        )

        var key: Data?
        var digest: Data?

        if isImage {
            let asset = assetClientMessage.underlyingMessage?.assetData?.uploaded
            key = asset?.otrKey
            digest = asset?.sha256
        } else {
            let asset = assetClientMessage.underlyingMessage?.assetData?.preview.remote
            key = asset?.otrKey
            digest = asset?.sha256
        }

        queue.async {
            guard let cache else {
                completionHandler(nil)
                return
            }

            if let mediumKey,
               let key,
               let digest,
               let data = cache.decryptData(
                   key: mediumKey,
                   encryptionKey: key,
                   sha256Digest: digest
               ) {
                completionHandler(data)
            } else if let fallbackKey {
                completionHandler(cache.assetData(fallbackKey))
            } else {
                completionHandler(nil)
            }
        }
    }

    // MARK: Fileprivate

    fileprivate let assetClientMessage: ZMAssetClientMessage
    fileprivate let moc: NSManagedObjectContext

    fileprivate var isImage: Bool {
        assetClientMessage.underlyingMessage?.v3_isImage ?? false
    }
}

// MARK: AssetProxyType

extension V3Asset: AssetProxyType {
    public var hasDownloadedPreview: Bool {
        guard !isImage else { return false }
        return moc.zm_fileAssetCache.hasImageData(for: assetClientMessage)
    }

    public var hasDownloadedFile: Bool {
        if isImage {
            moc.zm_fileAssetCache.hasImageData(for: assetClientMessage)
        } else {
            moc.zm_fileAssetCache.hasFileData(for: assetClientMessage)
        }
    }

    public var fileURL: URL? {
        if moc.zm_fileAssetCache.hasEncryptedFileData(for: assetClientMessage) {
            guard let asset = assetClientMessage.underlyingMessage?.assetData?.uploaded else {
                return nil
            }

            return moc.zm_fileAssetCache.temporaryURLForDecryptedFile(
                for: assetClientMessage,
                encryptionKey: asset.otrKey,
                sha256Digest: asset.sha256
            )
        } else if moc.zm_fileAssetCache.hasOriginalFileData(for: assetClientMessage) {
            return moc.zm_fileAssetCache.accessAssetURL(assetClientMessage)
        } else {
            return nil
        }
    }

    public func requestFileDownload() {
        guard !assetClientMessage.objectID.isTemporaryID else { return }
        NotificationInContext(
            name: ZMAssetClientMessage.assetDownloadNotificationName,
            context: moc.notificationContext,
            object: assetClientMessage.objectID
        ).post()
    }

    public func requestPreviewDownload() {
        if assetClientMessage.underlyingMessage?.assetData?.hasPreview == true {
            guard !assetClientMessage.objectID.isTemporaryID else { return }
            NotificationInContext(
                name: ZMAssetClientMessage.imageDownloadNotificationName,
                context: moc.notificationContext,
                object: assetClientMessage.objectID
            ).post()
        } else {
            return zmLog.info("Called \(#function) on a v3 asset that doesn't represent an image or has a preview")
        }
    }
}
