//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireAccountImageUI
import WireDesign
import WireReusableUIComponents
public import UIKit
import WireLocators

public class ConversationTitleView: UIView {

    public private(set) var source: ConversationTitleSource

    private let accountImageView = AccountImageView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let legalHoldImage = UIImageView(image: UIImage(resource: .legalHold))
    private let verifiedImage = UIImageView(image: UIImage(resource: .verified))
    private let dropdownImage = UIImageView(image: .dropdown)
    private let tapButton = UIButton(type: .custom)

    private let canAnimate: Bool

    public var menuProvider: (() -> UIMenu)? {
        didSet {
            if let menu = menuProvider?() {
                tapButton.menu = menu
            }
        }
    }

    public init(source: ConversationTitleSource, canAnimate: Bool) {
        self.source = source
        self.canAnimate = canAnimate
        super.init(frame: CGRect.zero)
        configureViews()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.textColor = SemanticColors.Label.textDefault

        subtitleLabel.font = .boldSystemFont(ofSize: 9)
        subtitleLabel.textColor = .white

        accountImageView.availability = nil
        accountImageView.hideProfileNotificationsBadge = true

        let design = AccountImageViewDesign()
        accountImageView.imageBorderWidth = design.borderWidth
        accountImageView.imageBorderColor = design.borderColor
        accountImageView.initialsTextColor = SemanticColors.Button.textPrimaryEnabled

        dropdownImage.tintColor = ColorTheme.Backgrounds.onSurfaceVariant

        configureViewValues()
    }

    private func configureViewValues() {
        if let imageSource = source.accountImageSource {
            updateAvatar(source: imageSource, animated: true)
        }
        accountImageView.isHidden = source.accountImageSource == nil
        nameLabel.text = source.title
        subtitleLabel.text = source.subtitle
        subtitleLabel.isHidden = source.subtitle == nil
        legalHoldImage.isHidden = !source.isUnderLegalHold
        verifiedImage.isHidden = !source.isVerified
        verifiedImage.image = source.isMLS ? UIImage(resource: .certificateValid) : UIImage(resource: .verified)
    }

    private func configureLayout() {

        let stackView = UIStackView.vertical()
        addSubview(stackView)
        stackView.alignment = .center

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.pin(to: self)

        let avatarAndNameStackView = UIStackView.horizontal(spacing: 4)
        avatarAndNameStackView.alignment = .center

        [accountImageView, legalHoldImage, nameLabel, verifiedImage, dropdownImage.wrapInView(topInset: 4)]
            .forEach(avatarAndNameStackView.addArrangedSubview)

        [
            avatarAndNameStackView,
            subtitleLabel.wrapInView(topInset: -8, bottomInset: 6)
        ]
        .forEach(stackView.addArrangedSubview)

        accountImageView.constraintToSquare(sideLength: 26)
        legalHoldImage.constraintToSquare(sideLength: 16)
        verifiedImage.constraintToSquare(sideLength: 16)
        dropdownImage.constraintToSquare(sideLength: 16)
        stackView.heightAnchor.constraint(equalToConstant: 44).isActive = true

        stackView.center(in: self)

        addSubview(tapButton)
        tapButton.pin(to: self)
        tapButton.showsMenuAsPrimaryAction = true
        tapButton.accessibilityIdentifier = Locators.ActiveConversationPage.conversationTitleButton.rawValue
    }

    public func updateSource(_ source: ConversationTitleSource) {
        self.source = source
        configureViewValues()
    }

    public func updateOtherUserAccentColor(_ color: UIColor) {
        accountImageView.initialsBackgroundColor = color
    }

    public func updateSelfUserAccentColor(_ color: UIColor) {
        subtitleLabel.textColor = color
    }

    private func updateAvatar(source: AccountImageSource, animated: Bool) {
        let updateBlock = {
            self.accountImageView.source = source
        }

        if animated, canAnimate {
            UIView.transition(
                with: self,
                duration: 0.15,
                options: .transitionCrossDissolve,
                animations: updateBlock,
                completion: nil
            )
        } else {
            updateBlock()
        }
    }
}

@available(iOS 17, *)
#Preview("Account with Initials") {
    makeVC(source: ConversationTitleSource(
        accountImageSource: .text("DS"),
        title: "Wolfgang Wolf",
        subtitle: "FEDERATED",
        isMLS: false,
        isVerified: false,
        isUnderLegalHold: false
    ))

}

@available(iOS 17, *)
#Preview("Account with Image") {
    makeVC(source: ConversationTitleSource(
        accountImageSource: .image(.checkmark),
        title: "Paul Nagel",
        subtitle: "GUEST",
        isMLS: false,
        isVerified: false,
        isUnderLegalHold: false
    ))
}

@available(iOS 17, *)
#Preview("Account with Image Dark") {
    makeVC(source: ConversationTitleSource(
        accountImageSource: .image(.checkmark),
        title: "Paul Nagel",
        subtitle: "GUEST",
        isMLS: false,
        isVerified: false,
        isUnderLegalHold: false
    ), isDark: true)
}

@available(iOS 17, *)
#Preview("No subtitle") {
    makeVC(source: ConversationTitleSource(
        accountImageSource: .image(.checkmark),
        title: "John Snow",
        subtitle: nil,
        isMLS: false,
        isVerified: false,
        isUnderLegalHold: false
    ))
}

@available(iOS 17, *)
#Preview("LONG") {
    makeVC(source: ConversationTitleSource(
        accountImageSource: .image(.checkmark),
        title: "Paul Nagel NagelNagelNagelNagelNagelNagel",
        subtitle: nil,
        isMLS: false,
        isVerified: false,
        isUnderLegalHold: false
    ))
}

@available(iOS 17, *)
#Preview("Dark") {
    makeVC(source: ConversationTitleSource(
        accountImageSource: .image(.checkmark),
        title: "Paul Nagel NagelNagelNagelNagelNagelNagel",
        subtitle: nil,
        isMLS: false,
        isVerified: false,
        isUnderLegalHold: false
    ))
}

@MainActor
private func makeVC(source: ConversationTitleSource, isDark: Bool = false) -> UIViewController {
    let vc = UIViewController()
    vc.navigationItem.titleView = ConversationTitleView(
        source: source,
        canAnimate: false
    )
    vc.view.backgroundColor = .systemBackground
    let navigationController = UINavigationController(rootViewController: vc)
    let navBar = navigationController.navigationBar
    if isDark {
        navigationController.overrideUserInterfaceStyle = .dark
    }
    addBottomBorder(to: navBar)
    return navigationController
}

@MainActor
private func addBottomBorder(to navBar: UINavigationBar) {
    let border = UIView()
    border.backgroundColor = UIColor.lightGray
    border.translatesAutoresizingMaskIntoConstraints = false
    navBar.addSubview(border)

    NSLayoutConstraint.activate([
        border.bottomAnchor.constraint(equalTo: navBar.bottomAnchor),
        border.leadingAnchor.constraint(equalTo: navBar.leadingAnchor),
        border.trailingAnchor.constraint(equalTo: navBar.trailingAnchor),
        border.heightAnchor.constraint(equalToConstant: 1)
    ])
}
