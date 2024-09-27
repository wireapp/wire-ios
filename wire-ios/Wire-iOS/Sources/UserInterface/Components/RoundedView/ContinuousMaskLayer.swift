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
import WireSystem

// MARK: - MaskDimension

/// The dimension to use when calculating relative radii.
enum MaskDimension: Int {
    case width, height
}

// MARK: - MaskShape

/// Define the MaskShape enum to include the required shapes
enum MaskShape {
    case rectangle
    case circle
    case rounded(radius: CGFloat)
    case relative(multiplier: CGFloat, dimension: MaskDimension)

    // MARK: Internal

    enum Dimension {
        case width
        case height
    }
}

// MARK: - ContinuousMaskLayer

/// A layer whose corners are rounded with a continuous mask (“squircle“).
final class ContinuousMaskLayer: CALayer {
    // MARK: Lifecycle

    // MARK: - Initialization

    override init(layer: Any) {
        super.init(layer: layer)

        if let otherMaskLayer = layer as? ContinuousMaskLayer {
            self.shape = otherMaskLayer.shape
            self.roundedCorners = otherMaskLayer.roundedCorners
        } else {
            preconditionFailure("Cannot init with \(layer)")
        }
    }

    override init() {
        super.init()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // MARK: - Properties

    override var cornerRadius: CGFloat {
        didSet {
            // Ensure masksToBounds is set when cornerRadius is changed
            masksToBounds = cornerRadius > 0
        }
    }

    var shape: MaskShape = .rectangle {
        didSet {
            refreshMask()
        }
    }

    var roundedCorners: UIRectCorner = .allCorners {
        didSet {
            refreshMask()
        }
    }

    // MARK: - Layout

    override func layoutSublayers() {
        super.layoutSublayers()
        refreshMask()
    }

    // MARK: Private

    private func refreshMask() {
        switch shape {
        case .rectangle:
            cornerRadius = 0

        case .circle:
            cornerRadius = min(bounds.width, bounds.height) / 2

        case let .rounded(radius):
            cornerRadius = radius

        case let .relative(multiplier, dimension):
            let base: CGFloat = switch dimension {
            case .width: bounds.width
            case .height: bounds.height
            }

            cornerRadius = base * multiplier
        }

        masksToBounds = cornerRadius > 0
    }
}
