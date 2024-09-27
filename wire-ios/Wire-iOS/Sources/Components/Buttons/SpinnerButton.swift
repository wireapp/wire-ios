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
import WireReusableUIComponents

// MARK: - UIColor.AlarmButton

extension UIColor {
    enum AlarmButton {
        static let alarmRed = UIColor(rgb: 0xFB0807)
    }
}

// MARK: - SpinnerButton

/// A button with spinner at the trailing side. Title text is non truncated.
final class SpinnerButton: LegacyButton {
    // MARK: Lifecycle

    override init(fontSpec: FontSpec) {
        super.init(fontSpec: fontSpec)

        configureTitleLabel()
    }

    // MARK: Internal

    var isLoading = false {
        didSet {
            guard oldValue != isLoading else {
                return
            }

            spinner.isHidden = !isLoading
            spinner.isAnimating = isLoading
        }
    }

    // MARK: - factory method

    static func alarmButton() -> SpinnerButton {
        SpinnerButton(legacyStyle: .empty, cornerRadius: 6, fontSpec: .smallSemiboldFont)
    }

    /// custom full style with accent color for disabled state.
    override func updateFullStyle() {
        setBackgroundImageColor(UIColor.AlarmButton.alarmRed, for: .disabled)
        setBackgroundImageColor(UIColor.AlarmButton.alarmRed, for: .normal)

        setTitleColor(.white, for: .normal)
        setTitleColor(.white, for: .highlighted)
        setTitleColor(.white, for: .disabled)

        setTitleColor(UIColor.from(scheme: .textDimmed, variant: variant), for: .highlighted)
    }

    /// custom empty style with accent color for disabled state.
    override func updateEmptyStyle() {
        // remember reset background image colors when style is switch
        setBackgroundImageColor(.clear, for: .disabled)
        setBackgroundImageColor(.clear, for: .normal)

        layer.borderWidth = 1

        let states: [UIControl.State] = [.normal, .highlighted, .disabled]
        for state in states {
            let color: UIColor =
                switch variant {
                case .dark:
                    .white
                case .light:
                    UIColor.AlarmButton.alarmRed
                }

            setTitleColor(color, for: state)
            setBorderColor(UIColor.AlarmButton.alarmRed, for: state)
        }
    }

    // MARK: Private

    private lazy var spinner = {
        let spinner = Spinner()

        // the spinner covers the text with alpha BG
        spinner.backgroundColor = UIColor.from(scheme: .contentBackground)
            .withAlphaComponent(CGFloat.SpinnerButton.spinnerBackgroundAlpha)
        spinner.color = UIColor.AlarmButton.alarmRed
        spinner.iconSize = CGFloat.SpinnerButton.iconSize

        addSubview(spinner)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            spinner.trailingAnchor.constraint(equalTo: trailingAnchor),
            spinner.widthAnchor.constraint(equalToConstant: 48),
            spinner.topAnchor.constraint(equalTo: topAnchor),
            spinner.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        return spinner
    }()

    /// multi line support of titleLabel
    private func configureTitleLabel() {
        guard let titleLabel else {
            return
        }

        // title is always align to left
        contentHorizontalAlignment = .left

        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                greaterThanOrEqualTo: topAnchor,
                constant: CGFloat.SpinnerButton.contentInset
            ),
            titleLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: leadingAnchor,
                constant: CGFloat.SpinnerButton.contentInset
            ),
        ])
    }
}
