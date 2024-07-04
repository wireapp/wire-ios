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

import SwiftUI
import WireDesign

private let availableColor = ColorTheme.Base.positive
private let awayColor = ColorTheme.Base.error
private let busyColor = ColorTheme.Base.warning

// in the designs it's a 2px border width for size of 8.75 x 8.75 indicator view
private let awayRelativeBorderSize = 2.0 / 4.375

private let busyMaskRelativeRectangleWidth = 5.25 / 8.75
private let busyMaskRelativeRectangleHeight = 1.75 / 8.75

final class AvailabilityIndicatorView: UIView {

    var availability: Availability? {
        didSet { setNeedsLayout() }
    }

    // MARK: - Private Properties

    private let shapeView = UIView()

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Methods

    private func setupSubviews() {
        addSubview(shapeView)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let availability else {
            shapeView.backgroundColor = .none
            layer.mask = nil
            return
        }

        let diameter = min(bounds.width, bounds.height)
        let baseCircleFrame = CGRect(
            origin: .init(x: (bounds.width - diameter) / 2, y: (bounds.height - diameter) / 2),
            size: .init(width: diameter, height: diameter)
        )
        shapeView.frame = baseCircleFrame
        shapeView.layer.cornerRadius = diameter / 2

        switch availability {
        case .available:
            shapeView.backgroundColor = availableColor
            layer.mask = nil

        case .away:
            shapeView.backgroundColor = awayColor

            // mask with another circle, so that a ring results
            let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
            let radius = (baseCircleFrame.width / 2) * (1 - awayRelativeBorderSize)
            let maskPath = UIBezierPath(rect: bounds)
            maskPath.addArc(
                withCenter: center,
                radius: radius,
                startAngle: 0,
                endAngle: 2 * .pi,
                clockwise: true
            )
            let maskLayer = CAShapeLayer()
            maskLayer.path = maskPath.cgPath
            maskLayer.fillRule = .evenOdd
            layer.mask = maskLayer

        case .busy:
            shapeView.backgroundColor = busyColor

            // mask with a rectangle
            let maskPath = UIBezierPath(rect: bounds)
            let rectangleWidth = baseCircleFrame.width * busyMaskRelativeRectangleWidth
            let rectangleHeight = baseCircleFrame.height * busyMaskRelativeRectangleHeight
            let rectangleFrame = CGRect(
                x: (bounds.width - rectangleWidth) / 2,
                y: (bounds.height - rectangleHeight) / 2,
                width: rectangleWidth,
                height: rectangleHeight
            )
            maskPath.append(UIBezierPath(rect: rectangleFrame))
            let maskLayer = CAShapeLayer()
            maskLayer.path = maskPath.cgPath
            maskLayer.fillRule = .evenOdd
            layer.mask = maskLayer
        }
    }
}

// MARK: AvailabilityIndicatorView + init(availability:)

extension AvailabilityIndicatorView {

    public convenience init(availability: Availability) {
        self.init()
        self.availability = availability
        setNeedsLayout()
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    VStack {
        AvailabilityIndicatorViewRepresentable(availability: .none)
        AvailabilityIndicatorViewRepresentable(availability: .available)
        AvailabilityIndicatorViewRepresentable(availability: .away)
        AvailabilityIndicatorViewRepresentable(availability: .busy)
    }
    .background(Color(UIColor.systemGray2))
}

private struct AvailabilityIndicatorViewRepresentable: UIViewRepresentable {

    @State private(set) var availability: Availability?

    func makeUIView(context: Context) -> AvailabilityIndicatorView { .init() }

    func updateUIView(_ view: AvailabilityIndicatorView, context: Context) {
        view.availability = availability
    }
}
