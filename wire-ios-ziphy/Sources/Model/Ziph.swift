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

/// An item representing a post from Giphy.

public struct Ziph: Codable {
    public let identifier: String
    public let images: ZiphyAnimatedImageList
    public let title: String?

    // Some ziph do not have preview-gif KVP, use original instead
    public var previewImage: ZiphyAnimatedImage? {
        if let image = images[.preview] {
            return image
        }

        for imageType in ZiphyImageType.previewFallbackList {
            if let image = images[imageType] {
                return image
            }
        }

        return nil
    }

    public var description: String {
        "identifier: \(identifier)\n" +
            "title: \(title ?? "nil")\n" +
            "images:\n\(images)\n"
    }

    // MARK: - Initialization

    public init(identifier: String, images: ZiphyAnimatedImageList, title: String) {
        self.identifier = identifier
        self.images = images
        self.title = title
    }

    public enum CodingKeys: String, CodingKey {
        case title, images, identifier = "id"
    }
}
