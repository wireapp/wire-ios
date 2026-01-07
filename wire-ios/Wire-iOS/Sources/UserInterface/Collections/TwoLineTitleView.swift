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

final class TwoLineTitleView: UIView {

    // MARK: - Views

    // Fixed font sizes are used since this is a navigation bar titleView.
    // Instead of scaling with Dynamic Type, it uses UILargeContentViewer
    // for accessibility, consistent with iOS navigation bar behavior.
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = SemanticColors.Label.textDefault
        return label
    }()

    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = SemanticColors.Label.textDefault
        return label
    }()

    // MARK: - Properties

    private var originalTitle: NSAttributedString
    private var originalSubtitle: NSAttributedString?

    // MARK: - Life cycle

    init(first: NSAttributedString, second: NSAttributedString?) {
        self.originalTitle = first
        self.originalSubtitle = second

        super.init(frame: CGRect.zero)

        setupView()
        setupAccessibility()
        setupLargeContentViewer()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        titleLabel.textAlignment = .center
        subtitleLabel.textAlignment = .center

        titleLabel.attributedText = originalTitle
        subtitleLabel.attributedText = originalSubtitle

        addSubview(titleLabel)
        addSubview(subtitleLabel)

        [self, titleLabel, subtitleLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Accessibility

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .header

        let accessibilityText = [
            originalTitle.string,
            originalSubtitle?.string
        ].compactMap(\.self).joined(separator: ", ")

        accessibilityLabel = accessibilityText
    }

    private func setupLargeContentViewer() {
        showsLargeContentViewer = true
        scalesLargeContentImage = true

        if let subtitle = originalSubtitle?.string {
            largeContentTitle = originalTitle.string + "\n" + subtitle
        } else {
            largeContentTitle = originalTitle.string
        }
    }

}
