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
import WireDesign

final class WaveFormView: UIView {
    // MARK: Lifecycle

    init() {
        super.init(frame: CGRect.zero)
        configureViews()
        updateWaveFormColor()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var gradientWidth: CGFloat = 25 {
        didSet {
            leftGradientWidthConstraint.constant = gradientWidth
            rightGradientWidthConstraint.constant = gradientWidth
        }
    }

    var gradientColor: UIColor = SemanticColors.View.backgroundDefault {
        didSet {
            updateWaveFormColor()
        }
    }

    var color: UIColor = SemanticColors.View.backgroundDefault {
        didSet {
            visualizationView.waveColor = color
        }
    }

    func updateWithLevel(_ level: Float) {
        visualizationView.update(withLevel: level)
    }

    // MARK: Private

    private let visualizationView = SCSiriWaveformView()
    private let leftGradient = GradientView()
    private let rightGradient = GradientView()

    private lazy var leftGradientWidthConstraint: NSLayoutConstraint = leftGradient.widthAnchor
        .constraint(equalToConstant: gradientWidth)
    private lazy var rightGradientWidthConstraint: NSLayoutConstraint = rightGradient.widthAnchor
        .constraint(equalToConstant: gradientWidth)

    private func configureViews() {
        [visualizationView, leftGradient, rightGradient].forEach(addSubview)

        visualizationView.primaryWaveLineWidth = 1
        visualizationView.secondaryWaveLineWidth = 0.5
        visualizationView.numberOfWaves = 4
        visualizationView.waveColor = .accent()
        visualizationView.backgroundColor = UIColor.clear
        visualizationView.phaseShift = -0.3
        visualizationView.frequency = 1.7
        visualizationView.density = 10
        visualizationView.update(withLevel: 0) // Make sure we don't show any waveform

        let (midLeft, midRight) = (CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5))
        leftGradient.setStartPoint(midLeft, endPoint: midRight, locations: [0, 1])
        rightGradient.setStartPoint(midRight, endPoint: midLeft, locations: [0, 1])
    }

    private func createConstraints() {
        for item in [visualizationView, leftGradient, rightGradient] {
            item.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            visualizationView.topAnchor.constraint(equalTo: topAnchor),
            visualizationView.bottomAnchor.constraint(equalTo: bottomAnchor),
            visualizationView.leftAnchor.constraint(equalTo: leftAnchor),
            visualizationView.rightAnchor.constraint(equalTo: rightAnchor),

            topAnchor.constraint(equalTo: leftGradient.topAnchor),
            topAnchor.constraint(equalTo: rightGradient.topAnchor),
            bottomAnchor.constraint(equalTo: leftGradient.bottomAnchor),
            bottomAnchor.constraint(equalTo: rightGradient.bottomAnchor),

            leftAnchor.constraint(equalTo: leftGradient.leftAnchor),
            rightAnchor.constraint(equalTo: rightGradient.rightAnchor),
            leftGradientWidthConstraint,
            rightGradientWidthConstraint,
        ])
    }

    private func updateWaveFormColor() {
        let clearGradientColor = gradientColor.withAlphaComponent(0)
        let leftColors = [gradientColor, clearGradientColor].map(\.cgColor)
        leftGradient.gradientLayer.colors = leftColors
        rightGradient.gradientLayer.colors = leftColors
    }
}
