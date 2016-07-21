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

///Implementation of ZMImageOwner protocol. Used to store and access processed image data.
public class ImageOwner: NSObject, ZMImageOwner {
    
    var previewData: NSData? = nil
    var mediumData: NSData? = nil
    var imageData: NSData?
    
    public let imageSize: CGSize
    public let nonce: NSUUID
    
    public init(data: NSData, size: CGSize, nonce: NSUUID) {
        self.imageData = data
        self.imageSize = size
        self.nonce = nonce
    }
    
    public func setImageData(imageData: NSData!, forFormat format: ZMImageFormat, properties: ZMIImageProperties) {
        switch format {
        case .Preview:
            previewData = imageData
        case .Medium:
            mediumData = imageData
        default: break
        }
    }
    
    public func imageDataForFormat(format: ZMImageFormat) -> NSData! {
        switch format {
        case .Preview: return previewData
        case .Medium: return mediumData
        default: return nil
        }
    }
    
    public
    func requiredImageFormats() -> NSOrderedSet! {
        return NSOrderedSet(objects: ZMImageFormat.Preview.rawValue, ZMImageFormat.Medium.rawValue)
    }
    
    public func originalImageData() -> NSData! {
        return self.imageData
    }
    
    public func originalImageSize() -> CGSize {
        return self.imageSize
    }
    
    public func isInlineForFormat(format: ZMImageFormat) -> Bool {
        switch format {
        case .Preview: return true
        default: return false
        }
    }
    
    public func isPublicForFormat(format: ZMImageFormat) -> Bool {
        return false
    }
    
    public func isUsingNativePushForFormat(format: ZMImageFormat) -> Bool {
        return false
    }
    
    public func processingDidFinish() {
        imageData = nil
    }
    
    override public func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? ImageOwner {
            return object.nonce == self.nonce && CGSizeEqualToSize(object.imageSize, self.imageSize)
        }
        else {
            return false;
        }
    }
    
    override public var hash: Int {
        get {
            return nonce.hash ^ imageSize.width.hashValue ^ imageSize.height.hashValue
        }
    }
    
}
