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

final class GuestAccountWarningView: UIView {

    private let stackView = UIStackView(axis: .vertical)

    private let encryptionLabel = DynamicFontLabel(
        style: .subline1,
        color: SemanticColors.Label.textDefault
    )
    private let sensitiveInfoLabel = DynamicFontLabel(
        style: .subline1,
        color: SemanticColors.Label.textDefault
    )
    private let imageView = UIImageView(image: UIImage(named: "Info"))

    // MARK: - Setup

    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        typealias connectionView = L10n.Localizable.Conversation.ConnectionView

        stackView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        addSubview(imageView)
        imageView.tintColor = SemanticColors.Icon.foregroundPlainDownArrow
        stackView.alignment = .fill
        stackView.spacing = 30
        encryptionLabel.numberOfLines = 0
        encryptionLabel.text = connectionView.encryptionInfo
        stackView.addArrangedSubview(encryptionLabel)
        sensitiveInfoLabel.numberOfLines = 0
        sensitiveInfoLabel.text = connectionView.sensitiveInformationWarning
        stackView.addArrangedSubview(sensitiveInfoLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16.0),
            imageView.widthAnchor.constraint(equalToConstant: 16.0),
            imageView.heightAnchor.constraint(equalToConstant: 16.0),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.topAnchor.constraint(equalTo: sensitiveInfoLabel.topAnchor)
        ])
    }
}
