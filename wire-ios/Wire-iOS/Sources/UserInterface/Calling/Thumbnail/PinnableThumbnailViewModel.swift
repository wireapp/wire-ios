//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

struct PinnableThumbnailViewModel {

    func safeSize(containerSize: CGSize, safeAreaInsets: UIEdgeInsets) -> CGSize {
        CGSize(
            width: containerSize.width - safeAreaInsets.left - safeAreaInsets.right,
            height: containerSize.height - safeAreaInsets.top - safeAreaInsets.bottom
        )
    }

    func thumbnailFrame(
        contentSize: CGSize,
        parentSize: CGSize,
        edgeInsets: CGPoint,
        pinnedCenter: CGPoint?,
        isLeftToRightLayout: Bool,
        orientation: UIDeviceOrientation
    ) -> CGRect? {
        guard contentSize != .zero else { return nil }

        let size = contentSize.withOrientation(orientation)
        let position = thumbnailPosition(
            for: size,
            parentSize: parentSize,
            edgeInsets: edgeInsets,
            pinnedCenter: pinnedCenter,
            isLeftToRightLayout: isLeftToRightLayout
        )

        return CGRect(
            x: position.x - size.width / 2,
            y: position.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    func pannedFrame(
        originalFrame: CGRect,
        containerBounds: CGRect,
        originalCenter: CGPoint,
        translation: CGPoint
    ) -> CGRect {
        let transformedPoint = originalCenter.applying(
            CGAffineTransform(translationX: translation.x, y: translation.y)
        )

        let x = clampedOrigin(
            midpoint: transformedPoint.x,
            length: originalFrame.width,
            minimum: containerBounds.minX,
            maximum: containerBounds.maxX
        )
        let y = clampedOrigin(
            midpoint: transformedPoint.y,
            length: originalFrame.height,
            minimum: containerBounds.minY,
            maximum: containerBounds.maxY
        )

        return CGRect(x: x, y: y, width: originalFrame.width, height: originalFrame.height)
    }

    private func thumbnailPosition(
        for size: CGSize,
        parentSize: CGSize,
        edgeInsets: CGPoint,
        pinnedCenter: CGPoint?,
        isLeftToRightLayout: Bool
    ) -> CGPoint {
        if let pinnedCenter {
            return pinnedCenter
        }

        let frame = if isLeftToRightLayout {
            CGRect(
                x: parentSize.width - size.width - edgeInsets.x,
                y: edgeInsets.y,
                width: size.width,
                height: size.height
            )
        } else {
            CGRect(x: edgeInsets.x, y: edgeInsets.y, width: size.width, height: size.height)
        }

        return CGPoint(x: frame.midX, y: frame.midY)
    }

    private func clampedOrigin(
        midpoint: CGFloat,
        length: CGFloat,
        minimum: CGFloat,
        maximum: CGFloat
    ) -> CGFloat {
        let halfLength = length / 2

        if midpoint - halfLength < minimum {
            return minimum
        } else if midpoint + halfLength > maximum {
            return maximum - length
        } else {
            return midpoint - halfLength
        }
    }
}
