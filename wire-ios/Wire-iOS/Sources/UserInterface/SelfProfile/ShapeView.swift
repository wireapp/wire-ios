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

// MARK: - ShapeView

final class ShapeView: LayerHostView<CAShapeLayer> {
    // MARK: Internal

    var pathGenerator: ((CGSize) -> (UIBezierPath))? {
        didSet { updatePath() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !lastBounds.equalTo(bounds) {
            lastBounds = bounds
            updatePath()
        }
    }

    // MARK: Private

    private var lastBounds: CGRect = .zero

    private func updatePath() {
        guard let generator = pathGenerator else { return }
        hostedLayer.path = generator(bounds.size).cgPath
    }
}

// MARK: - LayerHostView

class LayerHostView<LayerType: CALayer>: UIView {
    override class var layerClass: AnyClass {
        LayerType.self
    }

    var hostedLayer: LayerType {
        layer as! LayerType
    }
}
