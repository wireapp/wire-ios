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
import WireLinkPreview

@objc extension ZMClientMessage {
    
    public static let linkPreviewImageDownloadNotification = NSNotification.Name(rawValue: "ZMClientMessageLinkPreviewImageDownloadNotificationName")
    
    public var linkPreviewState: ZMLinkPreviewState {
        set {
            let key = #keyPath(ZMClientMessage.linkPreviewState)
            self.willChangeValue(forKey: key)
            self.setPrimitiveValue(newValue.rawValue, forKey: key)
            self.didChangeValue(forKey: key)
            
            if newValue != .done {
                self.setLocallyModifiedKeys(Set([key]))
            }
        }
        get {
            let key = #keyPath(ZMClientMessage.linkPreviewState)
            self.willAccessValue(forKey: key)
            let raw = (self.primitiveValue(forKey: key) as? NSNumber) ?? 0
            self.didAccessValue(forKey: key)
            return ZMLinkPreviewState(rawValue: raw.int16Value)!
        }
    }
    
    public var linkPreview: LinkMetadata? {
        guard let linkPreview = self.firstZMLinkPreview else { return nil }
        if linkPreview.hasTweet() {
            return TwitterStatusMetadata(protocolBuffer: linkPreview)
        } else {
            let metadata = ArticleMetadata(protocolBuffer: linkPreview)
            guard !metadata.isBlacklisted else { return nil }
            return metadata
        }
    }

    /// Returns the first link attachment that we need to embed in the UI.
    public var mainLinkAttachment: LinkAttachment? {
        return linkAttachments?.first
    }
    
    var firstZMLinkPreview: ZMLinkPreview? {
        return self.genericMessage?.linkPreviews.first
    }
    
    static func keyPathsForValuesAffectingLinkPreview() -> Set<String> {
        return Set([#keyPath(ZMClientMessage.dataSet), #keyPath(ZMClientMessage.dataSet) + ".data"])
    }

    public func requestLinkPreviewImageDownload() {
        guard !self.objectID.isTemporaryID,
              self.linkPreview != nil,
              let moc = self.managedObjectContext,
              let linkPreview = self.firstZMLinkPreview else { return }
        
        guard linkPreview.article.image.uploaded.hasAssetId() || linkPreview.image.uploaded.hasAssetId(), !hasDownloadedImage() else { return }
        
        NotificationInContext(name: ZMClientMessage.linkPreviewImageDownloadNotification, context: moc.notificationContext, object: self.objectID).post()
    }
    
    public func fetchLinkPreviewImageData(with queue: DispatchQueue, completionHandler: @escaping (_ imageData: Data?) -> Void) {
        guard let cache = managedObjectContext?.zm_fileAssetCache else { return }
        let originalKey =  FileAssetCache.cacheKeyForAsset(self, format: .original)
        let mediumKey =  FileAssetCache.cacheKeyForAsset(self, format: .medium)
        
        queue.async {
            completionHandler([mediumKey, originalKey].lazy.compactMap({ $0 }).compactMap({ cache.assetData($0) }).first)
        }
    }
    
    func applyLinkPreviewUpdate(_ updatedMessage: ZMGenericMessage, from updateEvent: ZMUpdateEvent) {
        guard let nonce = self.nonce,
              let senderUUID = updateEvent.senderUUID(),
              let originalText = genericMessage?.textData,
              let updatedText = updatedMessage.textData,
              senderUUID == sender?.remoteIdentifier,
              originalText.content == updatedText.content
        else { return }
        
        let expiresAfter = deletionTimeout > 0 ? deletionTimeout : nil
        add(ZMGenericMessage.message(content: originalText.updateLinkPeview(from: updatedText), nonce: nonce, expiresAfter: expiresAfter).data())
    }
    
}


extension ZMClientMessage: ZMImageOwner {
    
    @objc public func imageData(for format: ZMImageFormat) -> Data? {
        return self.managedObjectContext?.zm_fileAssetCache.assetData(self, format: format, encrypted: false)
    }
    
    // The image formats that this @c ZMImageOwner wants preprocessed. Order of formats determines order in which data is preprocessed
    @objc public func requiredImageFormats() -> NSOrderedSet {
        if let genericMessage = self.genericMessage, genericMessage.linkPreviews.count > 0 {
            return NSOrderedSet(array: [ZMImageFormat.medium.rawValue])
        }
        return NSOrderedSet()
    }
    
    @objc public func originalImageData() -> Data? {
        return self.managedObjectContext?.zm_fileAssetCache.assetData(self, format: .original, encrypted: false)
    }
    
    @objc public func originalImageSize() -> CGSize {
        guard let originalImageData = self.originalImageData() else { return CGSize.zero }
        return ZMImagePreprocessor.sizeOfPrerotatedImage(with: originalImageData)
    }
        
    @objc public func processingDidFinish() {
        self.linkPreviewState = .processed
        guard let moc = self.managedObjectContext else { return }
        moc.zm_fileAssetCache.deleteAssetData(self, format: .original, encrypted: false)
        moc.enqueueDelayedSave()
    }
    
    @objc public var linkPreviewImageData: Data? {
        return self.managedObjectContext?.zm_fileAssetCache.assetData(self, format: .original, encrypted: false)
            ?? self.managedObjectContext?.zm_fileAssetCache.assetData(self, format: .medium, encrypted: false)
    }
    
    @objc public var linkPreviewHasImage: Bool {
        guard let linkPreview = self.firstZMLinkPreview else { return false }
        return linkPreview.article.hasImage() || linkPreview.hasImage()
    }
    
    @objc public var linkPreviewImageCacheKey: String? {
        return self.nonce?.uuidString
    }

    @objc public func setImageData(_ imageData: Data, for format: ZMImageFormat, properties: ZMIImageProperties?) {
        guard format == .medium else { return }
        guard let linkPreview = self.firstZMLinkPreview else { return }
        guard let moc = self.managedObjectContext else { return }
        
        moc.zm_fileAssetCache.storeAssetData(self, format: format, encrypted: false, data: imageData)
        guard let keys = moc.zm_fileAssetCache.encryptImageAndComputeSHA256Digest(self, format: format) else { return }
        
        let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: Int32(properties?.size.width ?? 0), height: Int32(properties?.size.height ?? 0))
        let original = ZMAssetOriginal.original(withSize: UInt64(imageData.count), mimeType: properties?.mimeType ?? "", name: nil, imageMetaData: imageMetaData)
        
        let updatedPreview = linkPreview.update(withOtrKey: keys.otrKey, sha256: keys.sha256!, original: original)

        if let genericMessage = self.genericMessage, let textMessageData = textMessageData {
            
            let text = ZMText.text(with: textMessageData.messageText ?? "", mentions: textMessageData.mentions, linkPreviews: [updatedPreview])
            let messageUpdate: MessageContentType

            if genericMessage.hasText() {
                messageUpdate = text
            } else if genericMessage.hasEphemeral() && genericMessage.ephemeral.hasText() {
                messageUpdate = ZMEphemeral.ephemeral(content: text, expiresAfter: deletionTimeout)
            } else if genericMessage.hasEdited(), let replacingMessageID = UUID(uuidString: genericMessage.edited.replacingMessageId) {
                messageUpdate = ZMMessageEdit.edit(with: text, replacingMessageId: replacingMessageID)
            } else {
                return
            }
            
            self.add(ZMGenericMessage.message(content: messageUpdate, nonce: nonce!).data())
        }
        
        moc.enqueueDelayedSave()
    }
}

