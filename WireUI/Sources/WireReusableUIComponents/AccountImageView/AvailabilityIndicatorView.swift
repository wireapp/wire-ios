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

final class AvailabilityIndicatorView: UIView {

    var availability: Availability? {
        didSet { setNeedsLayout() }
    }

    // MARK: - Private Properties

    private let shapeLayer = CAShapeLayer()

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
        layer.addSublayer(shapeLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        switch availability {

        case .none:
            break

        case .available:
            let diameter = min(bounds.width, bounds.height)
            let frame = CGRect(
                origin: .init(x: center.x - diameter / 2, y: center.y - diameter / 2),
                size: .init(width: diameter, height: diameter)
            )
            shapeLayer.path = UIBezierPath(ovalIn: frame).cgPath
            shapeLayer.fillColor = availableColor.cgColor

        case .some(.busy):
            break

        case .some(.away):
            break

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
