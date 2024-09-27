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

extension CGSize {
    /// returns the longest length among width and height
    var longestLength: CGFloat {
        width > height ? width : height
    }

    var shortestLength: CGFloat {
        width > height ? height : width
    }
}

// MARK: - CGFloat.Image

extension CGFloat {
    enum Image {
        /// Maximum image size that would show in a UIImageView.
        /// Tested on iPhone 5s and found that the image size limitation is ~5000px
        static let maxSupportedLength: CGFloat = 5000
    }
}

extension UIImage {
    @objc
    func downsizedImage() -> UIImage? {
        downsized()
    }

    /// downsize an image to the size which the longer side length equal to maxLength
    ///
    /// - Parameter maxLength: The maxLength of the resized image
    /// - Returns: an image with longer side length equal to maxLength, return nil if fail to scale the image
    func downsized(maxLength: CGFloat = CGFloat.Image.maxSupportedLength) -> UIImage? {
        let longestLength = size.longestLength

        guard longestLength > maxLength else {
            return self
        }

        let ratio = maxLength / longestLength / UIScreen.main.scale
        return imageScaled(with: ratio)
    }

    /// downsize an image to the size which the shorter side length equal to shorterSizeLength
    ///
    /// - Parameter shorterSizeLength: The target shorter size of the resized image
    /// - Returns: an image with shorter side length equal to shorterSizeLength, return nil if fail to scale the image
    func downsized(shorterSizeLength: CGFloat) -> UIImage? {
        let shortestLength = size.shortestLength

        guard shortestLength > shorterSizeLength else {
            return self
        }

        let ratio = shorterSizeLength / shortestLength / UIScreen.main.scale
        return imageScaled(with: ratio)
    }
}
