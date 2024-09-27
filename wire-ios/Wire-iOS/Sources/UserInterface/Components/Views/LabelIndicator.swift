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
import WireCommonComponents
import WireDesign

// MARK: - LabelIndicatorContext

enum LabelIndicatorContext {
    case guest,
         groupRole,
         external,
         federated

    // MARK: Internal

    var icon: StyleKitIcon {
        switch self {
        case .guest:
            .guest
        case .groupRole:
            .groupAdmin
        case .external:
            .externalPartner
        case .federated:
            .federated
        }
    }

    var title: String {
        switch self {
        case .guest:
            L10n.Localizable.Profile.Details.guest
        case .groupRole:
            L10n.Localizable.Profile.Details.groupAdmin
        case .external:
            L10n.Localizable.Profile.Details.partner
        case .federated:
            L10n.Localizable.Profile.Details.federated
        }
    }
}

// MARK: - LabelIndicator

final class LabelIndicator: UIView {
    // MARK: Lifecycle

    init(context: LabelIndicatorContext) {
        self.context = context
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private let indicatorIcon = UIImageView()
    private let titleLabel = DynamicFontLabel(
        fontSpec: .mediumSemiboldInputText,
        color: SemanticColors.Label.textDefault
    )
    private let containerView = UIView()
    private let context: LabelIndicatorContext

    private func setupViews() {
        var accessibilityString = switch context {
        case .guest:
            "guest"
        case .groupRole:
            "group_role"
        case .external:
            "team_role"
        case .federated:
            "federated"
        }

        titleLabel.accessibilityIdentifier = "label." + accessibilityString
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left
        titleLabel.text = context.title.capitalized

        indicatorIcon.accessibilityIdentifier = "img." + accessibilityString

        indicatorIcon.setTemplateIcon(context.icon, size: .nano)
        indicatorIcon.tintColor = SemanticColors.Icon.foregroundDefault

        containerView.addSubview(titleLabel)
        containerView.addSubview(indicatorIcon)
        accessibilityIdentifier = accessibilityString + " indicator"

        addSubview(containerView)
    }

    private func createConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        indicatorIcon.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: containerView.topAnchor),

            // containerView
            containerView.leadingAnchor.constraint(equalTo: safeLeadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: safeTrailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: safeBottomAnchor),

            // indicatorIcon
            indicatorIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            indicatorIcon.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),

            // titleLabel
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: indicatorIcon.trailingAnchor, constant: 6),
        ])
    }
}
