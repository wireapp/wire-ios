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

extension UIImage {
    public var imageWithAlphaTrimmed: UIImage {
        let originalSize = size

        var minX = Int.max
        var maxX = Int.min
        var minY = Int.max
        var maxY = Int.min
        var nonAlphaBounds = CGRect.zero
        var trimmedImage: UIImage = self

        UIGraphicsBeginImageContextWithOptions(originalSize, false, scale)

        draw(at: CGPoint.zero)

        if let context = UIGraphicsGetCurrentContext(),
           var pixelData = context.data?.assumingMemoryBound(to: UInt32.self) {
            let alignment = (8 - (context.width % 8)) % 8

            for y in 0 ..< context.height * 1 {
                for x in 0 ..< context.width * 1 {
                    let alpha = UInt8((pixelData.pointee >> 24) & 255)

                    if alpha > 0 {
                        minX = min(x, minX)
                        maxX = max(x, maxX)
                        minY = min(y, minY)
                        maxY = max(y, maxY)
                    }

                    pixelData = pixelData.successor()
                }
                pixelData = pixelData.advanced(by: alignment)
            }

            nonAlphaBounds = CGRect(
                x: CGFloat(minX) / scale,
                y: CGFloat(minY) / scale,
                width: CGFloat(maxX - minX) / scale,
                height: CGFloat(maxY - minY) / scale
            )
        }

        UIGraphicsEndImageContext()

        UIGraphicsBeginImageContextWithOptions(nonAlphaBounds.size, false, scale)

        draw(at: CGPoint(x: -nonAlphaBounds.origin.x, y: -nonAlphaBounds.origin.y))

        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            trimmedImage = image
        }

        UIGraphicsEndImageContext()

        return trimmedImage
    }
}
