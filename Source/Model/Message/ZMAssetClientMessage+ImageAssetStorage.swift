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

extension ZMAssetClientMessage: ImageAssetStorage {

    @objc public func genericMessage(for format: ZMImageFormat) -> ZMGenericMessage? {
        switch format {
        case .medium:
            return self.mediumGenericMessage
        case .preview:
            return self.previewGenericMessage
        default:
            return nil
        }
    }
    
    @objc public func shouldReprocess(for format: ZMImageFormat) -> Bool {
        guard let moc = self.managedObjectContext else { return false }
        let originalImageData = moc.zm_fileAssetCache.assetData(self,
                                                                format: format,
                                                                encrypted: false)
        let encryptedImageData = moc.zm_fileAssetCache.assetData(self,
                                                                 format: format,
                                                                 encrypted: true)
        return encryptedImageData == nil && originalImageData != nil
    }

    @objc public func originalImageData() -> Data? {
        return self.managedObjectContext?.zm_fileAssetCache.assetData(self,
                                                                      format: .original,
                                                                      encrypted: false)
    }

    @objc public func isPublic(for format: ZMImageFormat) -> Bool {
        return false
    }

    @objc public func setImageData(_ imageData: Data, for format: ZMImageFormat, properties: ZMIImageProperties?) {
        guard let moc = self.managedObjectContext else { return }
        moc.zm_fileAssetCache.storeAssetData(self, format: format, encrypted: false, data: imageData)
        guard let keys = moc.zm_fileAssetCache.encryptImageAndComputeSHA256Digest(self, format: format) else { return }
        
        if self.imageMessageData != nil {
            self.processAddedImage(with: format, properties: properties, encryptionKeys: keys)
            self.updateCategoryCache()
        } else if (self.fileMessageData != nil) {
            self.processAddedFilePreview(
                with: format,
                properties: properties,
                encryptionKeys: keys,
                imageData: imageData)
        } else {
            fatal("Message should represent either an image or a file")
        }
        moc.enqueueDelayedSave()
    }
    
    private func processAddedImage(with format: ZMImageFormat,
                                   properties: ZMIImageProperties?,
                                   encryptionKeys: ZMImageAssetEncryptionKeys)
    {
        self.asset?.processAddedImage(format: format, properties: properties!, keys: encryptionKeys)
    }
    
    private func processAddedFilePreview(with format: ZMImageFormat,
                                         properties: ZMIImageProperties?,
                                         encryptionKeys: ZMImageAssetEncryptionKeys,
                                         imageData: Data)
    {
        require(format == .medium, "File message preview should only be in format 'medium'")
        
        let imageMetadata = ZMAssetImageMetaData.imageMetaData(withWidth: Int32(properties?.size.width ?? 0),
                                                               height: Int32(properties?.size.height ?? 0))
        let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: encryptionKeys.otrKey, sha256: encryptionKeys.sha256!)
        let preview = ZMAssetPreview.preview(withSize: UInt64(imageData.count),
                                             mimeType: properties?.mimeType ?? "",
                                             remoteData: remoteData,
                                             imageMetaData: imageMetadata)
        let builder = ZMAsset.builder()!
        builder.setPreview(preview)
        let asset = builder.build()!
        let filePreviewMessage = ZMGenericMessage.message(content: asset, nonce: nonce!, expiresAfter: deletionTimeout)
        
        self.add(filePreviewMessage)
    }
    
    @objc public func imageData(for format: ZMImageFormat) -> Data? {
        return self.imageData(for: format, encrypted: false)
    }
    
    @objc public func imageData(for format: ZMImageFormat, encrypted: Bool) -> Data? {
        return self.asset?.imageData(for: format, encrypted: encrypted)
    }

    @objc public func updateMessage(imageData: Data, for format: ZMImageFormat) -> AnyObject? {
        guard let moc = self.managedObjectContext else { return nil }
        
        moc.zm_fileAssetCache.storeAssetData(self,
                                             format: format,
                                             encrypted: self.hasEncryptedAsset,
                                             data: imageData)
        if self.hasEncryptedAsset {
            let otrKey: Data?
            let sha256: Data?
            
            if self.fileMessageData != nil {
                let remote = self.genericAssetMessage?.assetData?.preview.remote
                otrKey = remote?.otrKey
                sha256 = remote?.sha256
            } else if self.imageMessageData != nil {
                let imageAsset = self.genericMessage(for: format)?.imageAssetData
                otrKey = imageAsset?.otrKey
                sha256 = imageAsset?.sha256
            } else {
                otrKey = nil
                sha256 = nil
            }
            
            var decrypted = false
            if let otrKey = otrKey, let sha256 = sha256 {
                decrypted = moc.zm_fileAssetCache.decryptImageIfItMatchesDigest(self,
                                                                                format: format,
                                                                                encryptionKey: otrKey,
                                                                                sha256Digest: sha256)
            }
            
            if !decrypted && self.imageMessageData != nil {
                moc.delete(self)
                return nil
            }
        }
        return self
    }
    
    @objc public func originalImageSize() -> CGSize {
        return self.imageMessageData?.originalSize ?? CGSize.zero
    }
    
    @objc public func requiredImageFormats() -> NSOrderedSet {
        return self.asset?.requiredImageFormats ?? NSOrderedSet()
    }
    
    @objc public func isInline(for format: ZMImageFormat) -> Bool {
        switch format {
        case .preview:
            return true
        default:
            return false
        }
    }

    @objc public func isUsingNativePush(for format: ZMImageFormat) -> Bool {
        switch format {
        case .medium:
            return true
        default:
            return false
        }
    }

    @objc public func processingDidFinish() {
        guard let moc = self.managedObjectContext else { return }
        moc.zm_fileAssetCache.deleteAssetData(self,
                                              format: .original,
                                              encrypted: false)
        moc.enqueueDelayedSave()
    }
    
    var imageFormat: ZMImageFormat {
        let genericMessage = self.mediumGenericMessage ?? self.previewGenericMessage
        return genericMessage?.imageAssetData?.imageFormat() ?? .invalid
        
    }

}
