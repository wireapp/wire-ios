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
import MobileCoreServices


private let zmLog = ZMSLog(tag: "AssetV3")


/// This protocol is used to hide the implementation of the different
/// asset types (v2 image & file vs. v3 file) from ZMAssetClientMessage.
/// It only includes methods in which these two versions differentiate.
@objc public protocol AssetProxyType {
    var hasDownloadedImage: Bool { get }
    var hasDownloadedFile: Bool { get }
    var imageMessageData: ZMImageMessageData? { get }
    var fileURL: URL? { get }

    var previewData: Data? { get }
    var imagePreviewDataIdentifier: String? { get }

    @objc(imageDataForFormat:encrypted:)
    func imageData(for: ZMImageFormat, encrypted: Bool) -> Data?

    func requestFileDownload()
    func requestImageDownload()
}


@objc public class V3Asset: NSObject, ZMImageMessageData {

    fileprivate let assetClientMessage: ZMAssetClientMessage
    private let assetStorage: ZMImageAssetStorage
    fileprivate let moc: NSManagedObjectContext

    fileprivate var isImage: Bool {
        return assetClientMessage.genericAssetMessage?.v3_isImage ?? false
    }

    public init?(with message: ZMAssetClientMessage) {
        guard message.version == 3, let storage = message.imageAssetStorage else { return nil }
        assetClientMessage = message
        assetStorage = storage
        moc = message.managedObjectContext!
    }

    public var imageMessageData: ZMImageMessageData? {
        guard isImage || (nil != assetClientMessage.fileMessageData && hasDownloadedImage) else { return nil }
        return self
    }

    public var mediumData: Data? {
        guard nil != assetClientMessage.fileMessageData, isImage else { return nil }
        return imageData(for: .medium, encrypted: false)
    }

    public var imageData: Data? {
        guard nil != assetClientMessage.fileMessageData, isImage else { return nil }
        return mediumData ?? imageData(for: .original, encrypted: false)
    }

    public var imageDataIdentifier: String? {
        if nil != assetClientMessage.fileMessageData, isImage, let image = assetClientMessage.genericAssetMessage?.assetData?.original.image {
            return "\(assetClientMessage.nonce.transportString())-\(image.width)x\(image.height)"
        }

        return imageData.map { String(format: "orig-%p", $0 as NSData) }
    }

    public var imagePreviewDataIdentifier: String? {
        return previewData != nil ? assetClientMessage.genericAssetMessage?.previewAssetId : nil
    }

    public var previewData: Data? {
        guard nil != assetClientMessage.fileMessageData, !isImage, assetClientMessage.hasDownloadedImage else { return nil }
        return imageData(for: .medium, encrypted: false)
    }

    public var isAnimatedGIF: Bool {
        return assetClientMessage.genericAssetMessage?.assetData?.original.mimeType.isGIF ?? false
    }

    public var imageType: String? {
        guard isImage else { return nil }
        return assetClientMessage.genericAssetMessage?.assetData?.original.mimeType
    }

    public var originalSize: CGSize {
        guard nil != assetClientMessage.fileMessageData, isImage else { return .zero }
        guard let asset = assetClientMessage.genericAssetMessage?.assetData else { return .zero }
        guard asset.original.hasImage(), asset.original.image.width > 0 else { return assetClientMessage.preprocessedSize }
        let size = CGSize(width: Int(asset.original.image.width), height: Int(asset.original.image.height))
        if size != .zero {
            return size
        }

        return assetClientMessage.preprocessedSize
    }

}

extension V3Asset: AssetProxyType {

    public var hasDownloadedImage: Bool {
        var downloaded = nil != imageData(for: .medium, encrypted: false)
        if isImage {
            downloaded = downloaded || nil != imageData(for: .original, encrypted: false)
        }
        return downloaded
    }

    public var hasDownloadedFile: Bool {
        guard !isImage else { return false }
        return hasFile(for: assetClientMessage.genericAssetMessage?.v3_fileCacheKey)
    }

    public var fileURL: URL? {
        guard let key = assetClientMessage.genericAssetMessage?.v3_fileCacheKey else { return nil }
        return moc.zm_fileAssetCache.accessAssetURL(assetClientMessage.nonce, fileName: key)
    }

    public func imageData(for format: ZMImageFormat, encrypted: Bool) -> Data? {
        guard assetClientMessage.fileMessageData != nil else { return nil }
        return moc.zm_imageAssetCache.assetData(assetClientMessage.nonce, format: format, encrypted: encrypted)
    }

    public func requestFileDownload() {
        guard assetClientMessage.fileMessageData != nil else { return }
        if (isImage && !hasDownloadedImage) || (!isImage && !hasDownloadedFile) {
            assetClientMessage.transferState = .downloading
        }
    }

    public func requestImageDownload() {
        guard isImage else { return zmLog.info("Called \(#function) on a v3 asset that doesn't represent an image") }
        requestFileDownload()
    }

    // MARK: - Helper

    private func hasFile(for key: String?) -> Bool {
        guard let cacheKey = key else { return false }
        return moc.zm_fileAssetCache.hasDataOnDisk(assetClientMessage.nonce, fileName: cacheKey, encrypted: false)
    }
}
