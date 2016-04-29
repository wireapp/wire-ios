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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation


import zimages
import ZMProtos

/// Wrapper of generic message that implements ZMImageOwner
/// It needs AssetCache to be able to retrieve image data
@objc public class ZMGenericMessageImageOwner :NSObject, ZMImageOwner {
    
    private let genericMessage : ZMGenericMessage
    private let assetCache : ImageAssetCache
    
    public init(genericMessage: ZMGenericMessage, assetCache: ImageAssetCache) {
        self.genericMessage = genericMessage
        self.assetCache = assetCache
    }
    
    public func setImageData(imageData: NSData!, forFormat format: ZMImageFormat, properties: ZMIImageProperties!) {
        // noop
    }
    
    private var encrypted : Bool {
        return self.genericMessage.hasImage() && self.genericMessage.image.otrKey.length > 0
    }
    
    private var nonce : NSUUID? {
        if self.genericMessage.hasImage() {
            return NSUUID.uuidWithTransportString(self.genericMessage.messageId)
        }
        return nil;
    }
    
    public func originalImageData() -> NSData! {
        guard let nonce = self.nonce where self.genericMessage.hasImage() else { return nil }
        return self.assetCache.assetData(nonce, format: .Original, encrypted: false)
    }
    
    public func isPublicForFormat(format: ZMImageFormat) -> Bool {
        return false;
    }
    
    public func imageDataForFormat(format: ZMImageFormat) -> NSData! {
        guard let nonce = self.nonce where
            self.genericMessage.hasImage()
                && format == self.genericMessage.image.imageFormat()
            else { return nil }
        return self.assetCache.assetData(nonce, format: format, encrypted: self.encrypted)
    }
    
    public func originalImageSize() -> CGSize {
        if self.genericMessage.hasImage() {
            return CGSize(width: CGFloat(self.genericMessage.image.originalWidth), height: CGFloat(self.genericMessage.image.originalHeight))
        }
        return CGSize(width: 0,height: 0)
    }
    
    public func requiredImageFormats() -> NSOrderedSet! {
        return NSOrderedSet()
    }
    
    public func isInlineForFormat(format: ZMImageFormat) -> Bool {
        return format == .Preview
    }
    
    public func isUsingNativePushForFormat(format: ZMImageFormat) -> Bool {
        return format == .Medium
    }
    
    public func processingDidFinish() {
        
    }
    
    public var imageFormat : ZMImageFormat {
        if self.genericMessage.hasImage() {
            return self.genericMessage.image.imageFormat()
        }
        return .Invalid;
    }
}


