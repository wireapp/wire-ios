//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireDataModel

final class ProfileTitleView: UIView {

    typealias LabelColors = SemanticColors.Label

    let verifiedImageView = UIImageView(image: WireStyleKit.imageOfShieldverified)
    private let titleLabel = DynamicFontLabel(fontSpec: .normalMediumFont,
                                              color: LabelColors.textDefault)

    var showVerifiedShield = false {
        didSet {
            updateVerifiedShield()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        verifiedImageView.accessibilityIdentifier = "VerifiedShield"

        titleLabel.accessibilityIdentifier = "user_profile.name"
        titleLabel.textAlignment = .center
        titleLabel.backgroundColor = .clear

        addSubview(titleLabel)
        addSubview(verifiedImageView)
    }

    private func createConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        verifiedImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
          titleLabel.topAnchor.constraint(equalTo: topAnchor),
          titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
          titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
          titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

          verifiedImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
          verifiedImageView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 10)
        ])
    }

    func configure(with user: UserType) {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        let userStatus = UserStatus(
            user: user,
            isCertified: false // TODO [WPB-765]: provide value after merging into `epic/e2ei`
        )
        titleLabel.attributedText = userStatus.title(
            color: LabelColors.textDefault,
            includeAvailability: selfUser.isTeamMember,
            includeVerificationStatus: false,
            appendYouSuffix: false
        )
        setupAccessibility()
    }

    private func updateVerifiedShield() {
        UIView.transition(
            with: verifiedImageView,
            duration: 0.2,
            options: .transitionCrossDissolve,
            animations: { self.verifiedImageView.isHidden = !self.showVerifiedShield }
        )
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .header
        accessibilityLabel = titleLabel.text
    }
}
