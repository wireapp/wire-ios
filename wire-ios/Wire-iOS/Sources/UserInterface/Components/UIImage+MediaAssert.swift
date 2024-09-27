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

extension UIImage: MediaAsset {
    var imageData: Data? {
        if isTransparent {
            pngData()
        } else {
            jpegData(compressionQuality: 1.0)
        }
    }

    var isGIF: Bool {
        false
    }

    var isTransparent: Bool {
        guard let alpha: CGImageAlphaInfo = cgImage?.alphaInfo else {
            return false
        }

        switch alpha {
        case .alphaOnly, .first, .last, .premultipliedFirst, .premultipliedLast:
            return true
        default:
            return false
        }
    }
}
