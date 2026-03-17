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
import WireCommonComponents
import WireDesign
import WireLocators
import WireSyncEngine

final class UserConnectionView: UIView, Copyable {

    convenience init(instance: UserConnectionView) {
        self.init(user: instance.user, userSession: instance.userSession)
    }

    private static var correlationFormatter: AddressBookCorrelationFormatter = .init(
        lightFont: FontSpec(.small, .light),
        boldFont: FontSpec(.small, .medium),
        color: SemanticColors.Label.textDefault
    )

    private let firstLabel = UILabel()
    private let secondLabel = UILabel()
    private let labelContainer = UIStackView(axis: .vertical)
    private let userImageView = UserImageView()
    private let guestIndicator = LabelIndicator(context: .guest)
    private let guestWarningView = GuestAccountWarningView()
    private let guestWarningContainer = UIView()
    private let userSession: UserSession

    var user: UserType {
        didSet {
            updateLabels()
            userImageView.user = user
        }
    }

    init(user: UserType, userSession: UserSession) {
        self.user = user
        self.userSession = userSession
        super.init(frame: .zero)
        userImageView.userSession = userSession
        setup()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        labelContainer.spacing = 0.0
        backgroundColor = .clear
        [firstLabel, secondLabel].forEach {
            $0.numberOfLines = 0
            $0.textAlignment = .center
        }

        userImageView.accessibilityLabel = "user image"
        userImageView.size = .big
        userImageView.user = user

        [labelContainer, userImageView, guestIndicator, guestWarningContainer].forEach(addSubview)

        guestWarningContainer.addSubview(guestWarningView)
        guestWarningContainer.backgroundColor = SemanticColors.View.backgroundGreen

        [firstLabel, secondLabel].forEach(labelContainer.addArrangedSubview)

        guestIndicator.isHidden = true

        updateLabels()
        updateGuestAccountViews()
    }

    private func updateLabels() {
        updateFirstLabel()
        updateSecondLabel()
    }

    private func updateFirstLabel() {
        if let handleText = handleLabelText {
            firstLabel.attributedText = handleText
            firstLabel.accessibilityIdentifier = Locators.ConnectionRequestsPage.username.rawValue
        } else {
            firstLabel.attributedText = correlationLabelText
            firstLabel.accessibilityIdentifier = "correlation"
        }
    }

    private func updateSecondLabel() {
        guard handleLabelText != nil else { return }
        secondLabel.attributedText = correlationLabelText ?? NSAttributedString(string: "")
        secondLabel.accessibilityIdentifier = "correlation"
    }

    private var handleLabelText: NSAttributedString? {
        guard let handle = user.handleDisplayString(withDomain: user.isFederated), !handle.isEmpty else { return nil }

        return handle && [
            .foregroundColor: SemanticColors.Label.textDefault,
            .font: UIFont.smallSemiboldFont
        ]
    }

    private var correlationLabelText: NSAttributedString? {
        type(of: self).correlationFormatter.correlationText(
            for: user,
            addressBookName: (user as? ZMUser)?.addressBookEntry?.cachedName
        )
    }

    private func createConstraints() {
        [
            userImageView,
            labelContainer,
            guestIndicator,
            guestWarningView,
            guestWarningContainer
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            labelContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelContainer.topAnchor.constraint(equalTo: topAnchor, constant: 16.0),
            labelContainer.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor),

            userImageView.topAnchor.constraint(equalTo: labelContainer.bottomAnchor, constant: 16.0),
            userImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            userImageView.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor, constant: 54),
            userImageView.widthAnchor.constraint(equalTo: userImageView.heightAnchor),
            userImageView.heightAnchor.constraint(equalToConstant: 200),

            guestIndicator.topAnchor.constraint(equalTo: userImageView.bottomAnchor, constant: 8.0),
            guestIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),

            guestWarningContainer.topAnchor.constraint(equalTo: guestIndicator.bottomAnchor, constant: 0),
            guestWarningContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            guestWarningContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            guestWarningContainer.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])

        guestWarningView.fitIn(view: guestWarningContainer, insets: .init(top: 12, left: 16, bottom: 12, right: 16))
    }

    private func updateGuestAccountViews() {
        if let viewer = SelfUser.provider?.providedSelfUser {
            if viewer.hasTeam {
                if user.hasTeam {
                    let isSameTeam = user.isOnSameTeam(otherUser: viewer)
                    guestIndicator.isHidden = isSameTeam
                } else {
                    guestIndicator.isHidden = false
                }
            } else {
                guestIndicator.isHidden = true
            }
        }
    }
}
