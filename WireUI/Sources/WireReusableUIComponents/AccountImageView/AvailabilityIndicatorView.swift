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

// #1D7833 light
// #30DB5B dark
private let availableColor = UIColor {
    $0.userInterfaceStyle == .dark
    ? .init(red: 0.19, green: 0.86, blue: 0.36, alpha: 1)
    : .init(red: 0.11, green: 0.47, blue: 0.20, alpha: 1)
}

// #C20013 light
// #FF7770 dark
private let awayColor = UIColor {
    $0.userInterfaceStyle == .dark
    ? .init(red: 1.00, green: 0.47, blue: 0.44, alpha: 1)
    : .init(red: 0.76, green: 0.00, blue: 0.07, alpha: 1)
}

// #A25915 light
// #FFD426 dark
private let busyColor = UIColor {
    $0.userInterfaceStyle == .dark
    ? .init(red: 1.00, green: 0.83, blue: 0.15, alpha: 1)
    : .init(red: 0.64, green: 0.35, blue: 0.08, alpha: 1)
}

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

// MARK: - Previews

struct AvailabilityIndicatorView_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            AvailabilityIndicatorViewRepresentable(.none)
            AvailabilityIndicatorViewRepresentable(.available)
            AvailabilityIndicatorViewRepresentable(.away)
            AvailabilityIndicatorViewRepresentable(.busy)
        }
        .background(Color(UIColor.systemGray2))
    }
}

private struct AvailabilityIndicatorViewRepresentable: UIViewRepresentable {

    private(set) var availability: Availability?

    init(_ availability: Availability?) {
        self.availability = availability
    }

    func makeUIView(context: Context) -> AvailabilityIndicatorView {
        let view = AvailabilityIndicatorView()
        view.availability = availability
        return view
    }

    func updateUIView(_ view: AvailabilityIndicatorView, context: Context) {
        view.availability = availability
    }
}
