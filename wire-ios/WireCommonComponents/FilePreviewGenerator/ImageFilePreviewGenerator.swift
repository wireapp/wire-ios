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

import UIKit
import UniformTypeIdentifiers

struct ImageFilePreviewGenerator: FilePreviewGenerator {

    let thumbnailSize: CGSize

    func supportsPreviewGenerationForFile(at url: URL) -> Bool {
        url.uniformType?.conforms(to: .image) ?? false
    }

    func generatePreviewForFile(at url: URL) throws -> UIImage {

        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw Error.failedToCreatePreview
        }
        let options: [AnyHashable: Any] = [
            kCGImageSourceCreateThumbnailWithTransform as AnyHashable: true,
            kCGImageSourceCreateThumbnailFromImageAlways as AnyHashable: true,
            kCGImageSourceThumbnailMaxPixelSize as AnyHashable: max(thumbnailSize.width, thumbnailSize.height)
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary?) else {
            throw Error.failedToCreatePreview
        }
        return UIImage(cgImage: thumbnail)
    }

    // MARK: -

    enum Error: Swift.Error {
        case failedToCreatePreview
    }
}
