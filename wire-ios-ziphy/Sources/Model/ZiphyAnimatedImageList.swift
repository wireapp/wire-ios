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

// MARK: - ZiphyAnimatedImageList

/// A list of images, sorted by their type. When decoding from JSON, only
/// valid images will be included.

public struct ZiphyAnimatedImageList: Codable {
    fileprivate let images: [ZiphyImageType: ZiphyAnimatedImage]

    public init(images: [ZiphyImageType: ZiphyAnimatedImage]) {
        self.images = images
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ZiphyImageType.self)
        var images: [ZiphyImageType: ZiphyAnimatedImage] = [:]

        for imageType in container.allKeys {
            images[imageType] = try? container.decode(ZiphyAnimatedImage.self, forKey: imageType)
        }

        self.images = images
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ZiphyImageType.self)

        for (type, image) in images {
            try container.encode(image, forKey: type)
        }
    }
}

// MARK: Sequence

extension ZiphyAnimatedImageList: Sequence {
    public typealias RawValue = [ZiphyImageType: ZiphyAnimatedImage]

    /// Returns the image for the specified type.
    public subscript(type: ZiphyImageType) -> ZiphyAnimatedImage? {
        images[type]
    }

    public var count: Int {
        images.count
    }

    public func makeIterator() -> RawValue.Iterator {
        images.makeIterator()
    }
}
