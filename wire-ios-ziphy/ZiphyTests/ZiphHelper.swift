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
@testable import Ziphy

final class ZiphHelper {
    static func createZiph(id: String, url: URL) -> Ziph {
        let imagesList: [ZiphyImageType: ZiphyAnimatedImage] = [
            .preview: ZiphyAnimatedImage(url: url, width: 300, height: 200, fileSize: 51200),
            .fixedWidthDownsampled: ZiphyAnimatedImage(url: url, width: 300, height: 200, fileSize: 204800),
            .original: ZiphyAnimatedImage(url: url, width: 300, height: 200, fileSize: 2048000),
            .downsized: ZiphyAnimatedImage(url: url, width: 300, height: 200, fileSize: 5000000)
        ]

        return createZiph(id: id, url: url, imagesList: imagesList)
    }

    static func createZiph(id: String, url: URL, imagesList: [ZiphyImageType: ZiphyAnimatedImage]) -> Ziph {

        let ziph = Ziph(identifier: id, images: ZiphyAnimatedImageList(images: imagesList), title: id)

        return ziph
    }
}
