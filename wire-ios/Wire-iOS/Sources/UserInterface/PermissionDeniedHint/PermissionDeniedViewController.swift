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

final class PermissionDeniedViewController: UIViewController {
    // MARK: Lifecycle

    // MARK: - Initialization

    required init() {
        super.init(nibName: nil, bundle: nil)

        setupHeroLabel()
        createSettingsButton()
        createLaterButton()
        updateViewConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: Internal

    // MARK: - Properties

    weak var delegate: PermissionDeniedViewControllerDelegate?

    let heroLabel = UILabel()
    private(set) var settingsButton: LegacyButton!
    private(set) var laterButton: UIButton!

    // MARK: - Constraints

    override func updateViewConstraints() {
        super.updateViewConstraints()

        guard !initialConstraintsCreated else { return }

        initialConstraintsCreated = true

        for item in [heroLabel, settingsButton, laterButton] {
            item?.translatesAutoresizingMaskIntoConstraints = false
        }

        var constraints = [
            heroLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            heroLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
        ]

        constraints += [
            settingsButton.topAnchor.constraint(equalTo: heroLabel.bottomAnchor, constant: 28),
            settingsButton.heightAnchor.constraint(equalToConstant: 56),
        ]

        constraints += [
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            settingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
        ]

        constraints += [
            laterButton.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 28),
            laterButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -28
            ),
            laterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            laterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            laterButton.heightAnchor.constraint(equalToConstant: 56),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: Private

    private var initialConstraintsCreated = false

    // MARK: - Setup Buttons

    private func setupHeroLabel() {
        heroLabel.textColor = SemanticColors.Label.textDefault
        heroLabel.numberOfLines = 0
        view.addSubview(heroLabel)
    }

    private func createSettingsButton() {
        settingsButton = ZMButton(
            style: .accentColorTextButtonStyle,
            cornerRadius: 16,
            fontSpec: .normalSemiboldFont
        )
        settingsButton.addTarget(self, action: #selector(openSettings(_:)), for: .touchUpInside)

        view.addSubview(settingsButton)
    }

    private func createLaterButton() {
        laterButton = ZMButton(
            style: .secondaryTextButtonStyle,
            cornerRadius: 16,
            fontSpec: .normalSemiboldFont
        )
        laterButton.addTarget(self, action: #selector(continueWithoutAccess(_:)), for: .touchUpInside)

        view.addSubview(laterButton)
    }

    // MARK: - Actions

    @objc
    private func openSettings(_: Any?) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        delegate?.permissionDeniedViewControllerDidOpenNotificationSettings(self)
    }

    @objc
    private func continueWithoutAccess(_: Any?) {
        delegate?.permissionDeniedViewControllerDidSkip(self)
    }
}
