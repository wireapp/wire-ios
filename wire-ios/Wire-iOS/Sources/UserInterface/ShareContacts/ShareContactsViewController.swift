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

// MARK: - String Extension

extension String {

    func withCustomParagraphSpacing() -> NSMutableAttributedString {

        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 10

        return .init(
            string: self,
            attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle]
        )
    }
}

// MARK: - ShareContactsViewController

final class ShareContactsViewController: UIViewController {

    // MARK: - Properties

    typealias RegistrationShareContacts = L10n.Localizable.Registration.ShareContacts

    weak var delegate: ShareContactsViewControllerDelegate?

    private var uploadAddressBookImmediately = false
    private var backgroundBlurDisabled = false
    private var notNowButtonHidden = false
    private(set) var showingAddressBookAccessDeniedViewController = false

    private lazy var notNowButton = {
        let notNowButton = ZMButton(
            style: .secondaryTextButtonStyle,
            cornerRadius: 16,
            fontSpec: .normalSemiboldFont
        )
        notNowButton.setTitle(RegistrationShareContacts.SkipButton.title.capitalized, for: .normal)
        notNowButton.addTarget(self, action: #selector(shareContactsLater), for: .primaryActionTriggered)
        return notNowButton
    }()

    private let heroLabel: UILabel = {
        let heroLabel = UILabel()
        heroLabel.textColor = SemanticColors.Label.textDefault
        heroLabel.numberOfLines = 0
        heroLabel.font = FontSpec.largeSemiboldFont.font!
        heroLabel.attributedText = ShareContactsViewController.attributedHeroText
        return heroLabel
    }()

    private let shareContactsButton = {
        let shareContactsButton = ZMButton(
            style: .accentColorTextButtonStyle,
            cornerRadius: 16,
            fontSpec: .normalSemiboldFont
        )
        shareContactsButton.setTitle(RegistrationShareContacts.FindFriendsButton.title.capitalized, for: .normal)

        return shareContactsButton
    }()

    private let shareContactsContainerView = UIView()
    private let addressBookAccessDeniedViewController = PermissionDeniedViewController.addressBookAccessDeniedViewController()

    private static var attributedHeroText: NSAttributedString {
        let title = RegistrationShareContacts.Hero.title
        let paragraph = RegistrationShareContacts.Hero.paragraph

        let text = [title, paragraph].joined(separator: "\u{2029}")

        let attributedText = text.withCustomParagraphSpacing()

        attributedText.addAttributes([
            NSAttributedString.Key.foregroundColor: SemanticColors.Label.textDefault,
            NSAttributedString.Key.font: FontSpec.largeThinFont.font!
        ], range: (text as NSString).range(of: paragraph))

        return attributedText
    }

    // MARK: - Override methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        createConstraints()

        if AddressBookHelper.sharedHelper.isAddressBookAccessDisabled {
            displayContactsAccessDeniedMessage(animated: false)
        }
    }

    // MARK: - Setup

    private func setupViews() {

        view.addSubview(shareContactsContainerView)

        shareContactsContainerView.addSubview(heroLabel)

        notNowButton.isHidden = notNowButtonHidden
        shareContactsContainerView.addSubview(notNowButton)

        shareContactsButton.addTarget(self, action: #selector(shareContacts), for: .primaryActionTriggered)

        shareContactsContainerView.addSubview(shareContactsButton)

        addToSelf(addressBookAccessDeniedViewController)
        addressBookAccessDeniedViewController.delegate = self
        addressBookAccessDeniedViewController.view.isHidden = true
    }

    private func createConstraints() {

        shareContactsContainerView.translatesAutoresizingMaskIntoConstraints = false
        addressBookAccessDeniedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        heroLabel.translatesAutoresizingMaskIntoConstraints = false
        shareContactsButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            shareContactsContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            shareContactsContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            shareContactsContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            shareContactsContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            addressBookAccessDeniedViewController.view.topAnchor.constraint(equalTo: addressBookAccessDeniedViewController.view.superview!.topAnchor),
            addressBookAccessDeniedViewController.view.bottomAnchor.constraint(equalTo: addressBookAccessDeniedViewController.view.superview!.bottomAnchor),
            addressBookAccessDeniedViewController.view.leadingAnchor.constraint(equalTo: addressBookAccessDeniedViewController.view.superview!.leadingAnchor),
            addressBookAccessDeniedViewController.view.trailingAnchor.constraint(equalTo: addressBookAccessDeniedViewController.view.superview!.trailingAnchor),

            heroLabel.leadingAnchor.constraint(equalTo: heroLabel.superview!.leadingAnchor, constant: 28),
            heroLabel.trailingAnchor.constraint(equalTo: heroLabel.superview!.trailingAnchor, constant: -28),

            shareContactsButton.topAnchor.constraint(equalTo: heroLabel.bottomAnchor, constant: 24),
            shareContactsButton.heightAnchor.constraint(equalToConstant: 56),

            shareContactsButton.bottomAnchor.constraint(equalTo: shareContactsButton.superview!.bottomAnchor, constant: -28),
            shareContactsButton.leadingAnchor.constraint(equalTo: shareContactsButton.superview!.leadingAnchor, constant: 28),
            shareContactsButton.trailingAnchor.constraint(equalTo: shareContactsButton.superview!.trailingAnchor, constant: -28)
        ])
    }

    // MARK: - Actions

    @objc
    private func shareContacts() {
        AddressBookHelper.sharedHelper.requestPermissions { [weak self] success in
            guard let self else { return }
            if success {
                delegate?.shareContactsViewControllerDidFinish(self)
            } else {
                displayContactsAccessDeniedMessage(animated: true)
            }
        }
    }

    @objc
    private func shareContactsLater() {
        delegate?.shareContactsViewControllerDidSkip(self)
    }

    // MARK: - AddressBook Access Denied ViewController

    func displayContactsAccessDeniedMessage(animated: Bool) {
        endEditing()

        showingAddressBookAccessDeniedViewController = true

        if animated {
            UIView.transition(
                from: shareContactsContainerView,
                to: addressBookAccessDeniedViewController.view,
                duration: 0.35,
                options: [.showHideTransitionViews, .transitionCrossDissolve]
            )
        } else {
            shareContactsContainerView.isHidden = true
            addressBookAccessDeniedViewController.view.isHidden = false
        }
    }
}

// MARK: - ShareContactsViewController Extension

extension ShareContactsViewController: PermissionDeniedViewControllerDelegate {

    func permissionDeniedViewControllerDidSkip(_ viewController: PermissionDeniedViewController) {
        delegate?.shareContactsViewControllerDidSkip(self)
    }

    func permissionDeniedViewControllerDidOpenNotificationSettings(_ viewController: PermissionDeniedViewController) {
        // no op
    }
}
