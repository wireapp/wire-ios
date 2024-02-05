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
import WireDataModel
import WireSyncEngine

final class UserStatusViewController: UIViewController {

    private lazy var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    private let options: UserStatusView.Options
    private let user: UserType
    private let userSession: UserSession
    private let getSelfUserVerificationStatusUseCase: GetSelfUserVerificationStatusUseCaseProtocol

/// Used to update the `UserStatusView` on changes of a user.
private var userChangeObservation: NSObjectProtocol?

private var userStatusView: UserStatusView {
view as! UserStatusView
}

    init(
        user: UserType,
        options: UserStatusView.Options,
        userSession: UserSession,
        getSelfUserVerificationStatusUseCase: GetSelfUserVerificationStatusUseCaseProtocol
    ) {
        self.user = user
        self.options = options
        self.userSession = userSession
        self.getSelfUserVerificationStatusUseCase = getSelfUserVerificationStatusUseCase
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let view = UserStatusView(
            options: options,
            userSession: userSession
        )
        view.tapHandler = { [weak self] _ in self?.presentAvailabilityPicker() }

        updateUserStatusView()
        setupNotificationObservation()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateUserStatusView()
        }
    }

    private func presentAvailabilityPicker() {
        let alertViewController = UIAlertController.availabilityPicker { [weak self] availability in
            self?.didSelectAvailability(availability)
        }
        alertViewController.configPopover(pointToView: view)
        present(alertViewController, animated: true)
    }

    private func didSelectAvailability(_ availability: Availability) {
        let changes = { [weak self] in
            self?.user.availability = availability
            self?.feedbackGenerator.impactOccurred()
        }

        userSession.perform(changes)

        if Settings.shared.shouldRemindUserWhenChanging(availability) {
            present(UIAlertController.availabilityExplanation(availability), animated: true)
        }
    }

    private func provideHapticFeedback() {
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }

    // MARK: - Notifications

    private func setupNotificationObservation() {
        // refresh view when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUserStatusView),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        // refresh view when some user changes
        userChangeObservation = userSession.addUserObserver(self, for: user)
    }

    @objc
    private func updateUserStatusView() {
        userStatusView.userStatus = .init(
            name: user.name ?? "",
            availability: user.availability,
            isCertified: false,
            isVerified: false
        )
    }
}

// MARK: UserStatusViewController + UserObserving

extension UserStatusViewController: UserObserving {

    func userDidChange(_ changes: UserChangeInfo) {
        if changes.nameChanged || changes.availabilityChanged {
            updateUserStatusView()
        }
    }
}
