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

/// Implementation of ZMImageOwner protocol. Used to store and access processed image data.
public final class ImageOwner: NSObject, ZMImageOwner {
    var previewData: Data?
    var mediumData: Data?
    var imageData: Data?

    public let imageSize: CGSize
    public let nonce: UUID

    public init(data: Data, size: CGSize, nonce: UUID) {
        self.imageData = data
        self.imageSize = size
        self.nonce = nonce
    }

    public func setImageData(_ imageData: Data, for format: ZMImageFormat, properties: ZMIImageProperties?) {
        switch format {
        case .preview:
            previewData = imageData
        case .medium:
            mediumData = imageData
        default: break
        }
    }

    public func imageData(for format: ZMImageFormat) -> Data? {
        switch format {
        case .preview: previewData
        case .medium: mediumData
        default: nil
        }
    }

    public func requiredImageFormats() -> NSOrderedSet {
        NSOrderedSet(objects: ZMImageFormat.preview.rawValue, ZMImageFormat.medium.rawValue)
    }

    public func originalImageData() -> Data? {
        imageData
    }

    public func originalImageSize() -> CGSize {
        imageSize
    }

    public func isInline(for format: ZMImageFormat) -> Bool {
        switch format {
        case .preview: true
        default: false
        }
    }

    public func isPublic(for format: ZMImageFormat) -> Bool {
        false
    }

    public func isUsingNativePush(for format: ZMImageFormat) -> Bool {
        false
    }

    public func processingDidFinish() {
        imageData = nil
    }

    override public func isEqual(_ object: Any?) -> Bool {
        if let object = object as? ImageOwner {
            object.nonce == nonce && object.imageSize.equalTo(imageSize)
        } else {
            false
        }
    }

    override public var hash: Int {
        (nonce as NSUUID).hash ^ imageSize.width.hashValue ^ imageSize.height.hashValue
    }
}
