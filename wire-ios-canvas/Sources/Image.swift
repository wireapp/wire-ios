//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import UIKit

class Image: Editable {

    let image: UIImage
    var scale: CGFloat {
        didSet {
            updateImageTransform()
        }
    }
    var rotation: CGFloat {
        didSet {
            updateImageTransform()
        }
    }
    var position: CGPoint {
        didSet {
            updateImageTransform()
        }
    }
    var selected: Bool
    var selectable = true
    var imageView = UIImageView()

    var size: CGSize {
        return image.size
    }

    var bounds: CGRect {
        return CGRect(x: 0, y: 0, width: size.width, height: size.height).applying(transform)
    }

    var selectedView: UIView {
        return imageView
    }

    public init(image: UIImage, at position: CGPoint) {
        self.image = image
        self.scale = 1
        self.rotation = 0
        self.position = position
        self.selected = false
        self.imageView.image = image
        self.imageView.layer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        self.imageView.sizeToFit()

        updateImageTransform()
    }

    func draw(context: CGContext) {
        guard !selected else { return }

        context.saveGState()
        context.concatenate(transform)
        image.draw(at: CGPoint.zero)
        context.restoreGState()
    }

    var transform: CGAffineTransform {
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let toCenter = CGAffineTransform(translationX: -center.x, y: -center.y)
            let restoreCenter = CGAffineTransform(translationX: center.x, y: center.y)
            let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
            let rotationTransform = CGAffineTransform(rotationAngle: rotation)
            let translate = CGAffineTransform(translationX: position.x, y: position.y)

            return toCenter.concatenating(scaleTransform).concatenating(rotationTransform).concatenating(restoreCenter).concatenating(translate)
    }

    func sizeToFit(inRect rect: CGRect) {
        let scaleX = min(rect.size.width / image.size.width, 1.0)
        let scaleY = min(rect.size.height / image.size.height, 1.0)
        let center = CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2)

        position = center
        scale = min(scaleX, scaleY)
    }

    func updateImageTransform() {
        imageView.transform = transform
    }

}
