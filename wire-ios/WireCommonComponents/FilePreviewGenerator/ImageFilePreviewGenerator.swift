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
    let callbackQueue: OperationQueue

    func supportsPreviewGenerationForFile(at url: URL) -> Bool {
        url.uniformType?.conforms(to: .image) ?? false
    }

    func generatePreviewForFile(at url: URL) async throws -> UIImage {
        fatalError()
    }

    func generatePreviewForFile(at url: URL, uniformType: UTType, completion: @escaping (UIImage?) -> Void) {

        var result: UIImage? = .none
        defer {
            callbackQueue.addOperation {
                completion(result)
            }
        }

        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return }
        let options: [AnyHashable: Any] = [
            kCGImageSourceCreateThumbnailWithTransform as AnyHashable: true,
            kCGImageSourceCreateThumbnailFromImageAlways as AnyHashable: true,
            kCGImageSourceThumbnailMaxPixelSize as AnyHashable: max(thumbnailSize.width, thumbnailSize.height)
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary?) else { return }
        result = UIImage(cgImage: thumbnail)
    }
}
