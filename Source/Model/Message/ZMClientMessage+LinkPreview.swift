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

extension ZMClientMessage {
    
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
    
    public var linkPreview: LinkPreview? {
        
        guard let linkPreview = self.firstZMLinkPreview else { return nil }
        if linkPreview.hasTweet() {
            return TwitterStatus(protocolBuffer: linkPreview)
        } else if linkPreview.hasArticle() {
            return Article(protocolBuffer: linkPreview)
        }
        return nil
        
    }
    
    var firstZMLinkPreview: ZMLinkPreview? {
        return self.genericMessage?.linkPreviews.first
    }
    
    static func keyPathsForValuesAffectingLinkPreview() -> Set<String> {
        return Set([#keyPath(ZMClientMessage.dataSet), #keyPath(ZMClientMessage.dataSet) + ".data"])
    }

    public override func requestImageDownload() {
        guard !self.objectID.isTemporaryID,
            self.linkPreview != nil,
            let moc = self.managedObjectContext,
            let linkPreview = self.firstZMLinkPreview else {
                return
        }
        
        guard linkPreview.article.image.uploaded.hasAssetId() || linkPreview.image.uploaded.hasAssetId(),
            self.imageData == nil else { return }
        
        NotificationInContext(name: ZMClientMessage.linkPreviewImageDownloadNotification, context: moc.notificationContext, object: self.objectID).post()
    }
    
}


extension ZMClientMessage: ZMImageOwner {
    
    public func imageData(for format: ZMImageFormat) -> Data? {
        return self.managedObjectContext?.zm_fileAssetCache.assetData(self, format: format, encrypted: false)
    }
    
    // The image formats that this @c ZMImageOwner wants preprocessed. Order of formats determines order in which data is preprocessed
    public func requiredImageFormats() -> NSOrderedSet {
        if let genericMessage = self.genericMessage, genericMessage.linkPreviews.count > 0 {
            return NSOrderedSet(array: [ZMImageFormat.medium.rawValue])
        }
        return NSOrderedSet()
    }
    
    public func originalImageData() -> Data? {
        return self.managedObjectContext?.zm_fileAssetCache.assetData(self, format: .original, encrypted: false)
    }
    
    public func originalImageSize() -> CGSize {
        guard let originalImageData = self.originalImageData() else { return CGSize.zero }
        return ZMImagePreprocessor.sizeOfPrerotatedImage(with: originalImageData)
    }
    
    public func isInline(for format: ZMImageFormat) -> Bool {
        return false
    }
    
    public func isPublic(for format: ZMImageFormat) -> Bool {
        return false
    }
    
    public func isUsingNativePush(for format: ZMImageFormat) -> Bool {
        return false
    }
    
    public func processingDidFinish() {
        self.linkPreviewState = .processed
        guard let moc = self.managedObjectContext else { return }
        moc.zm_fileAssetCache.deleteAssetData(self, format: .original, encrypted: false)
        moc.enqueueDelayedSave()
    }
    
    var imageData: Data? {
        return self.managedObjectContext?.zm_fileAssetCache.assetData(self, format: .original, encrypted: false)
            ?? self.managedObjectContext?.zm_fileAssetCache.assetData(self, format: .medium, encrypted: false)
    }
    
    var hasImageData: Bool {        
        guard let linkPreview = self.firstZMLinkPreview else { return false }
        return linkPreview.article.hasImage() || linkPreview.hasImage()
    }
    
    public var imageDataIdentifier: String? {
        
        if self.imageData != nil {
            return self.nonce?.uuidString
        }
        
        guard let linkPreview = self.firstZMLinkPreview else { return nil }
        if linkPreview.article.hasImage() {
            return linkPreview.article.image.uploaded.assetId
        } else if linkPreview.hasImage() {
            return linkPreview.image.uploaded.assetId
        }
        return nil
    }
    
    public func setImageData(_ imageData: Data, for format: ZMImageFormat, properties: ZMIImageProperties?) {
        guard format == .medium else { return }
        guard let linkPreview = self.firstZMLinkPreview else { return }
        guard let moc = self.managedObjectContext else { return }
        
        moc.zm_fileAssetCache.storeAssetData(self, format: format, encrypted: false, data: imageData)
        guard let keys = moc.zm_fileAssetCache.encryptImageAndComputeSHA256Digest(self, format: format) else { return }
        
        let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: Int32(properties?.size.width ?? 0), height: Int32(properties?.size.height ?? 0))
        let original = ZMAssetOriginal.original(withSize: UInt64(imageData.count), mimeType: properties?.mimeType ?? "", name: nil, imageMetaData: imageMetaData)
        
        let updatedPreview = linkPreview.update(withOtrKey: keys.otrKey, sha256: keys.sha256!, original: original)
        
        if let genericMessage = self.genericMessage {
            if genericMessage.hasText() || (genericMessage.hasEphemeral() && genericMessage.ephemeral.hasText()) {
                let newMessage = ZMGenericMessage.message(text: self.textMessageData?.messageText ?? "",
                                                          linkPreview: updatedPreview,
                                                          nonce: self.nonce!.transportString(),
                                                          expiresAfter: self.deletionTimeout as NSNumber)
                self.add(newMessage.data())
            } else if genericMessage.hasEdited() {
                let newMessage = ZMGenericMessage(editMessage: genericMessage.edited.replacingMessageId,
                                                  newText: self.textMessageData?.messageText ?? "",
                                                  linkPreview: updatedPreview,
                                                  nonce: self.nonce!.transportString())
                self.add(newMessage.data())
            }
        }
        
        moc.enqueueDelayedSave()
    }
}

