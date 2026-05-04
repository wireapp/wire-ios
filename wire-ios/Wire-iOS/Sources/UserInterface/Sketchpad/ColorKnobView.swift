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
import WireDesign

final class ColorKnobView: UIView {

    // MARK: - Properties

    let knobOuterDiameter: CGFloat = 18

    var isSelected = false {
        didSet {
            borderCircleLayer.borderColor = knobBorderColor?.cgColor
            borderCircleLayer.borderWidth = isSelected ? 1 : 0
        }
    }

    var knobColor: UIColor? {
        didSet {
            innerCircleLayer.backgroundColor = knobColor?.cgColor
            innerCircleLayer.borderColor = knobBorderColor?.cgColor
            borderCircleLayer.borderColor = knobBorderColor?.cgColor
        }
    }

    var knobDiameter: CGFloat

    /// The actual circle knob, filled with the color
    private var innerCircleLayer: CALayer = .init()
    /// Just a layer, used for the thin border around the selected knob
    private var borderCircleLayer: CALayer = .init()

    // MARK: - Init

    init(knobDiameter: CGFloat) {
        self.knobDiameter = knobDiameter
        super.init(frame: .zero)

        layer.addSublayer(innerCircleLayer)
        layer.addSublayer(borderCircleLayer)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override method

    override func layoutSubviews() {
        super.layoutSubviews()

        let frame = frame
        let centerPos = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)

        let knobDiameter: CGFloat = knobDiameter + 1
        innerCircleLayer.bounds = CGRect(origin: .zero, size: CGSize(width: knobDiameter, height: knobDiameter))
        innerCircleLayer.position = centerPos
        innerCircleLayer.cornerRadius = knobDiameter / 2
        innerCircleLayer.borderWidth = 1

        borderCircleLayer.bounds = CGRect(
            origin: .zero,
            size: CGSize(
                width: knobOuterDiameter,
                height: knobOuterDiameter
            )
        )
        borderCircleLayer.position = centerPos
        borderCircleLayer.cornerRadius = knobOuterDiameter / 2
    }

    // MARK: - Helpers

    var knobBorderColor: UIColor? {
        knobColor == SemanticColors.DrawingColors.white ? .black : knobColor
    }
}
