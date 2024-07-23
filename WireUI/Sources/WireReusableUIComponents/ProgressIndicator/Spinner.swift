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

public final class Spinner: UIView {

    public var color: UIColor = .white {
        didSet { updateSpinnerIcon() }
    }

    public var iconSize: CGFloat = 32 {
        didSet { updateSpinnerIcon() }
    }

    public var isAnimating = false {
        didSet {
            guard oldValue != isAnimating else { return }

            if isAnimating {
                startAnimationInternal()
            } else {
                stopAnimationInternal()
            }
        }
    }

    private let spinner = UIImageView()

    private var isAnimationRunning: Bool {
        spinner.layer.animation(forKey: "rotateAnimation") != nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setup() {
        createSpinner()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        let frame = spinner.layer.frame
        spinner.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        spinner.layer.frame = frame
    }

    private func createSpinner() {
        spinner.contentMode = .center
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)

        updateSpinnerIcon()

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    override public var intrinsicContentSize: CGSize {
        spinner.image?.size ?? super.intrinsicContentSize
    }

    private func startAnimationInternal() {
        isHidden = false
        stopAnimationInternal()

        spinner.layer.add(ProgressIndicatorRotationAnimation(rotationSpeed: 1.4, beginTime: 0), forKey: "rotateAnimation")
    }

    private func stopAnimationInternal() {
        spinner.layer.removeAllAnimations()
    }

    func updateSpinnerIcon() {
        spinner.image = UIImage.imageForIcon(.spinner, size: iconSize, color: color)
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    {
        let container = UIView()
        container.backgroundColor = .black.withAlphaComponent(0.5)

        let spinner = Spinner()
        spinner.isAnimating = true
        spinner.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin]
        container.addSubview(spinner)
        spinner.center = container.center

        return container
    }()
}
