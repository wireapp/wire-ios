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


import zimages
import ZMProtos


/// Wrapper of generic message that implements ZMImageOwner
/// It needs AssetCache to be able to retrieve image data
@objc open class ZMGenericMessageImageOwner :NSObject, ZMImageOwner {
    
    fileprivate let genericMessage : ZMGenericMessage
    fileprivate let assetCache : ImageAssetCache
    
    public init(genericMessage: ZMGenericMessage, assetCache: ImageAssetCache) {
        self.genericMessage = genericMessage
        self.assetCache = assetCache
    }
    
    open func setImageData(_ imageData: Data!, for format: ZMImageFormat, properties: ZMIImageProperties!) {
        // noop
    }
    
    fileprivate var encrypted : Bool {
        return self.genericMessage.imageAssetData != nil && self.genericMessage.imageAssetData?.otrKey.count > 0
    }
    
    fileprivate var nonce : UUID? {
        if self.genericMessage.imageAssetData != nil {
            return UUID(uuidString: self.genericMessage.messageId)
        }
        return nil;
    }
    
    open func originalImageData() -> Data! {
        guard let nonce = self.nonce , self.genericMessage.imageAssetData != nil else { return nil }
        return self.assetCache.assetData(nonce, format: .original, encrypted: false)
    }
    
    open func isPublic(for format: ZMImageFormat) -> Bool {
        return false;
    }
    
    open func imageData(for format: ZMImageFormat) -> Data! {
        guard let nonce = self.nonce ,
              let image = self.genericMessage.imageAssetData, format == image.imageFormat()
        else { return nil }
        return self.assetCache.assetData(nonce, format: format, encrypted: self.encrypted)
    }
    
    open func originalImageSize() -> CGSize {
        if let imageAsset = self.genericMessage.imageAssetData {
            return CGSize(width: CGFloat(imageAsset.originalWidth), height: CGFloat(imageAsset.originalHeight))
        }
        return CGSize(width: 0,height: 0)
    }
    
    open func requiredImageFormats() -> NSOrderedSet! {
        return NSOrderedSet()
    }
    
    open func isInline(for format: ZMImageFormat) -> Bool {
        return format == .preview
    }
    
    open func isUsingNativePush(for format: ZMImageFormat) -> Bool {
        return format == .medium
    }
    
    open func processingDidFinish() {
        
    }
    
    open var imageFormat : ZMImageFormat {
        return self.genericMessage.imageAssetData?.imageFormat() ?? .invalid
    }
}


