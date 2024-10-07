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
import WireCommonComponents
import WireDataModel
import WireDesign
import WireSyncEngine

// TODO: ensure this view is displayed correctly everywhere
final class SecurityLevelView: UIView {

    // MARK: - Constants

    private static let SecurityLevelViewHeight = 24.0

    // MARK: - Properties

    private let securityLevelLabel = UILabel()
    private let iconImageView = UIImageView()
    private let topBorder = UIView()
    private let bottomBorder = UIView()

    typealias SecurityLocalization = L10n.Localizable.SecurityClassification
    typealias ViewColors = SemanticColors.View
    typealias LabelColors = SemanticColors.Label
    typealias IconColors = SemanticColors.Icon

    // MARK: - Initializers

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

    // MARK: - Methods

    func configure(with classification: SecurityClassification?) {
        securityLevelLabel.font = FontSpec.smallSemiboldFont.font!

        guard let classification, let levelText = classification.levelText else {
            isHidden = true
            return
        }

        configureCallingUI(with: classification)

        bottomBorder.backgroundColor = topBorder.backgroundColor

        let securityLevelText = SecurityLocalization.securityLevel.uppercased()
        securityLevelLabel.text = [
            securityLevelText,
            levelText
        ].joined(separator: " ")

        accessibilityIdentifier = "ClassificationBanner" + classification.accessibilitySuffix
    }

    func configure(
        with otherUsers: [UserType],
        conversationDomain: String?,
        provider: SecurityClassificationProviding? = ZMUserSession.shared()
    ) {
        guard let classification = provider?.classification(
            users: otherUsers,
            conversationDomain: conversationDomain
        ) else {
            isHidden = true
            return
        }

        configure(with: classification)
    }

    private func setupViews() {
        securityLevelLabel.textAlignment = .center
        iconImageView.contentMode = .scaleAspectFit

        [
            topBorder,
            securityLevelLabel,
            iconImageView,
            bottomBorder
        ].forEach { addSubview($0) }

        topBorder.addConstraintsForBorder(for: .top, borderWidth: 1.0, to: self)
        bottomBorder.addConstraintsForBorder(for: .bottom, borderWidth: 1.0, to: self)
    }

    private func createConstraints() {
        [
            securityLevelLabel,
            iconImageView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            securityLevelLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            securityLevelLabel.topAnchor.constraint(equalTo: topAnchor),
            securityLevelLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            securityLevelLabel.heightAnchor.constraint(equalToConstant: SecurityLevelView.SecurityLevelViewHeight),
            iconImageView.widthAnchor.constraint(equalToConstant: 11.0),
            iconImageView.heightAnchor.constraint(equalToConstant: 11.0),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            securityLevelLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 4)
        ])
    }

    private func configureCallingUI(with classification: SecurityClassification) {
        switch classification {

        case .classified:
            securityLevelLabel.textColor = LabelColors.textSecurityEnabled
            backgroundColor = ViewColors.backgroundSecurityEnabled
            iconImageView.image = .init(resource: .check)
            iconImageView.tintColor = IconColors.backgroundSecurityEnabledCheckMark
            topBorder.backgroundColor = ViewColors.borderSecurityEnabled

        case .notClassified:
            securityLevelLabel.textColor = LabelColors.textDefaultWhite
            backgroundColor = ViewColors.backgroundSecurityDisabled
            iconImageView.image = .init(resource: .attention)
            iconImageView.tintColor = IconColors.foregroundCheckMarkSelected
            topBorder.backgroundColor = .clear
        }
    }
}

// MARK: - SecurityClassification Extension

private extension SecurityClassification {

    typealias SecurityClassificationLevel = L10n.Localizable.SecurityClassification.Level

    var levelText: String? {
        switch self {

        case .classified:
            SecurityClassificationLevel.bund

        case .notClassified:
            L10n.Localizable.SecurityClassification.Level.notClassified
        }
    }

    var accessibilitySuffix: String {
        switch self {
        case .classified:
            "Classified"

        case .notClassified:
            "Unclassified"
        }
    }
}

// MARK: - Previews

struct SecurityLevelView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            SecurityLevelViewRepresentable(classification: .classified)
                .previewDisplayName("Classified")
            SecurityLevelViewRepresentable(classification: .notClassified)
                .previewDisplayName("Unclassified")
        }
    }
}

private struct SecurityLevelViewRepresentable: UIViewRepresentable {

    @State var classification: SecurityClassification?

    func makeUIView(context: Context) -> SecurityLevelView {
        let view = SecurityLevelView()
        view.configure(with: classification)
        return view
    }

    func updateUIView(_ view: SecurityLevelView, context: Context) {
        view.configure(with: classification)
    }
}
