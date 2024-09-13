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

import FLAnimatedImage
import Foundation
import MobileCoreServices
import UniformTypeIdentifiers

extension UIPasteboard {
    func pasteboardType(forMediaAsset mediaAsset: MediaAsset) -> String {
        if mediaAsset.isGIF {
            UTType.gif.identifier
        } else if mediaAsset.isTransparent {
            UTType.png.identifier
        } else {
            UTType.jpeg.identifier
        }
    }

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: get/set
    func mediaAsset() -> MediaAsset? {
        if contains(pasteboardTypes: [UTType.gif.identifier]) {
            let data: Data? = data(forPasteboardType: UTType.gif.identifier)
            return FLAnimatedImage(animatedGIFData: data)
        } else if contains(pasteboardTypes: [UTType.png.identifier]) {
            let data: Data? = data(forPasteboardType: UTType.png.identifier)
            if let aData = data {
                return UIImage(data: aData)
            }
            return nil
        } else if hasImages {
            return image
        }
        return nil
    }

    func setMediaAsset(_ image: MediaAsset?) {
        guard let image,
              let data = image.imageData else { return }

        UIPasteboard.general.setData(data, forPasteboardType: pasteboardType(forMediaAsset: image))
    }
}
