//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireDataModel
import WireSyncEngine
import WireCommonComponents

protocol ClassificationProviding {
    func classification(with users: [UserType], conversationDomain: String?) -> SecurityClassification
}

extension ZMUserSession: ClassificationProviding {}

final class SecurityLevelView: UIView {
    static let SecurityLevelViewHeight = 24.0
    private let securityLevelLabel = UILabel()
    private let iconImageView = UIImageView()
    private let topBorder = UIView()
    private let bottomBorder = UIView()
    typealias SecurityLocalization = L10n.Localizable.SecurityClassification

    typealias ViewColors = SemanticColors.View
    typealias LabelColors = SemanticColors.Label
    typealias IconColors = SemanticColors.Icon

    init() {
        super.init(frame: .zero)

        setupViews()
        createConstraints()

        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with classification: SecurityClassification) {
        securityLevelLabel.font = FontSpec.smallSemiboldFont.font!
        guard
            classification != .none,
            let levelText = classification.levelText
        else {
            isHidden = true
            return
        }

        configureCallingUI(with: classification)

        bottomBorder.backgroundColor = topBorder.backgroundColor

        let securityLevelText = SecurityLocalization.securityLevel.uppercased()
        securityLevelLabel.text = [securityLevelText, levelText].joined(separator: " ")

        accessibilityIdentifier = "ClassificationBanner" + classification.accessibilitySuffix
    }

    func configure(
        with otherUsers: [UserType],
        conversationDomain: String?,
        provider: ClassificationProviding? = ZMUserSession.shared()
    ) {

        guard let classification = provider?.classification(with: otherUsers, conversationDomain: conversationDomain) else {
            isHidden = true
            return
        }

        configure(with: classification)
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        securityLevelLabel.textAlignment = .center
        iconImageView.contentMode = .scaleAspectFit
        [topBorder, securityLevelLabel, iconImageView, bottomBorder].forEach { addSubview($0) }

        topBorder.addConstraintsForBorder(for: .top, borderWidth: 1.0, to: self)
        bottomBorder.addConstraintsForBorder(for: .bottom, borderWidth: 1.0, to: self)
    }

    private func createConstraints() {
        [securityLevelLabel, iconImageView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
          securityLevelLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
          securityLevelLabel.topAnchor.constraint(equalTo: topAnchor),
          securityLevelLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
          securityLevelLabel.heightAnchor.constraint(equalToConstant: SecurityLevelView.SecurityLevelViewHeight),
          iconImageView.widthAnchor.constraint(equalToConstant: 11.0),
          iconImageView.heightAnchor.constraint(equalToConstant: 11.0),
          iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
          iconImageView.trailingAnchor.constraint(equalTo: securityLevelLabel.leadingAnchor, constant: -4.0)
        ])
    }

    private func configureCallingUI(with classification: SecurityClassification) {
        switch classification {

        case .classified:
            securityLevelLabel.textColor = LabelColors.textSecurityEnabled
            backgroundColor = ViewColors.backgroundSecurityEnabled
            iconImageView.image = Asset.Images.check.image.withTintColor(IconColors.backgroundSecurityEnabledCheckMark)
            topBorder.backgroundColor = ViewColors.borderSecurityEnabled

        case .notClassified:
            securityLevelLabel.textColor = LabelColors.textDefaultWhite
            backgroundColor = ViewColors.backgroundSecurityDisabled
            iconImageView.image = Asset.Images.attention.image.withTintColor(IconColors.foregroundCheckMarkSelected)
            topBorder.backgroundColor = .clear

        case .none:
            isHidden = true
            assertionFailure("should not reach this point")
        }
    }

    private func configureLegacyCallingUI(with classification: SecurityClassification) {
        switch classification {

        case .classified:
            securityLevelLabel.textColor = LabelColors.textDefault
            backgroundColor = ViewColors.backgroundSecurityLevel
            iconImageView.setTemplateIcon(.checkmark, size: .tiny)
            iconImageView.tintColor = IconColors.backgroundCheckMarkSelected
            topBorder.backgroundColor = ViewColors.backgroundSeparatorCell

        case .notClassified:
            securityLevelLabel.textColor = LabelColors.textDefault
            backgroundColor = ViewColors.backgroundSecurityLevel
            iconImageView.setTemplateIcon(.exclamationMarkCircle, size: .tiny)
            iconImageView.tintColor = IconColors.foregroundCheckMarkSelected
            topBorder.backgroundColor = ViewColors.backgroundSeparatorCell

        case .none:
            isHidden = true
            assertionFailure("should not reach this point")
        }

    }
}

private extension SecurityClassification {

    typealias SecurityClassificationLevel = L10n.Localizable.SecurityClassification.Level

    var levelText: String? {
        switch self {
        case .classified:
            return SecurityClassificationLevel.bund

        case .notClassified:
            return L10n.Localizable.SecurityClassification.Level.notClassified

        default:
            return nil
        }
    }

    var accessibilitySuffix: String {
        switch self {
        case .classified:
            return "Classified"

        case .notClassified:
            return "Unclassified"

        default:
            return ""
        }
    }
}
