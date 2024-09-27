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
import WireSyncEngine

// MARK: - AppLockChangeWarningViewControllerDelegate

protocol AppLockChangeWarningViewControllerDelegate: AnyObject {
    func appLockChangeWarningViewControllerDidDismiss()
}

// MARK: - AppLockChangeWarningViewController

final class AppLockChangeWarningViewController: UIViewController {
    // MARK: - Properties

    weak var delegate: AppLockChangeWarningViewControllerDelegate?

    private var isAppLockActive: Bool
    private let userSession: UserSession

    private let contentView = UIView()

    private lazy var confirmButton = {
        let button = ZMButton(style: .primaryTextButtonStyle, cornerRadius: 16, fontSpec: .mediumSemiboldFont)
        button.accessibilityIdentifier = "warning_screen.button.confirm"
        button.setTitle(L10n.Localizable.General.confirm, for: .normal)
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel.createMultiLineCenterdLabel()
        label.text = L10n.Localizable.WarningScreen.titleLabel
        label.accessibilityIdentifier = "warning_screen.label.title"
        return label
    }()

    private lazy var messageLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            text: messageLabelText,
            fontSpec: .normalRegularFont,
            color: SemanticColors.Label.textDefault
        )
        label.textAlignment = .center
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.accessibilityIdentifier = "warning_screen.label.message"
        return label
    }()

    private var messageLabelText: String {
        if isAppLockActive {
            L10n.Localizable.WarningScreen.MainInfo.forcedApplock + "\n\n" + L10n.Localizable.WarningScreen.InfoLabel
                .forcedApplock
        } else {
            L10n.Localizable.WarningScreen.InfoLabel.nonForcedApplock
        }
    }

    // MARK: - Life cycle

    init(isAppLockActive: Bool, userSession: UserSession) {
        self.isAppLockActive = isAppLockActive
        self.userSession = userSession
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }

    // MARK: - Helpers

    private func setupViews() {
        view.backgroundColor = SemanticColors.View.backgroundDefault

        view.addSubview(contentView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(confirmButton)
        contentView.addSubview(messageLabel)

        createConstraints()
    }

    private func createConstraints() {
        [
            contentView,
            titleLabel,
            confirmButton,
            messageLabel,
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let contentPadding: CGFloat = 24

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // title Label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 150),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentPadding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentPadding),

            // message Label
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: contentPadding),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentPadding),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentPadding),

            // confirm Button
            confirmButton.heightAnchor.constraint(equalToConstant: CGFloat.WipeCompletion.buttonHeight),
            confirmButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -contentPadding),
            confirmButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentPadding),
            confirmButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentPadding),
        ])
    }

    // MARK: - Actions

    @objc
    func confirmButtonTapped(sender: AnyObject?) {
        userSession.perform {
            self.userSession.needsToNotifyUserOfAppLockConfiguration = false
        }

        dismiss(animated: true, completion: delegate?.appLockChangeWarningViewControllerDidDismiss)
    }
}
