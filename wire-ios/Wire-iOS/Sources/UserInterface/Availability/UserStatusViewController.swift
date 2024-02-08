//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let options: UserStatusView.Options
    private let user: UserType
    let userSession: UserSession

    /// Used to update the `UserStatusView` on changes of a user.
    private var userChangeObservation: NSObjectProtocol?

    public var userStatus: UserStatus {
        didSet { (view as? UserStatusView)?.userStatus = userStatus }
    }

    init(user: UserType, options: UserStatusView.Options, userSession: UserSession) {
        self.user = user
        self.options = options
        self.userSession = userSession

        userStatus = .init(
            name: user.name ?? "",
            availability: user.availability
        )

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
        view.tapHandler = { [weak self] _ in
            self?.presentAvailabilityPicker()
        }
        self.view = view

        // refresh view when some user changes
        userChangeObservation = userSession.addUserObserver(self, for: user)
    }

    func presentAvailabilityPicker() {
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
}

// MARK: UserStatusViewController + UserObserving

extension UserStatusViewController: UserObserving {

    func userDidChange(_ changes: UserChangeInfo) {
        if changes.nameChanged {
            userStatus.name = changes.user.name ?? ""
        }
        if changes.availabilityChanged {
            userStatus.availability = changes.user.availability
        }
    }
}
