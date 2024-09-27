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
    // MARK: Lifecycle

    init(
        options: UserStatusView.Options,
        settings: Settings
    ) {
        self.options = options
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    weak var delegate: UserStatusViewControllerDelegate?

    var userStatus = UserStatus() {
        didSet { (viewIfLoaded as? UserStatusView)?.userStatus = userStatus }
    }

    override func loadView() {
        let view = UserStatusView(options: options)
        view.userStatus = userStatus
        view.tapHandler = { [weak self] button in
            self?.presentAvailabilityPicker(button)
        }
        self.view = view
    }

    // MARK: Private

    private lazy var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    private let options: UserStatusView.Options
    private let settings: Settings

    private func presentAvailabilityPicker(_ sender: UIButton) {
        let availabilityChangedHandler = { [weak self] (availability: Availability) in
            guard let self else {
                return
            }

            delegate?.userStatusViewController(self, didSelect: availability)
            feedbackGenerator.impactOccurred()

            if settings.shouldRemindUserWhenChanging(availability) {
                present(UIAlertController.availabilityExplanation(availability), animated: true)
            }
        }

        let alertViewController = UIAlertController.availabilityPicker(availabilityChangedHandler)
        if let popoverPresentationController = alertViewController.popoverPresentationController {
            popoverPresentationController.sourceView = sender.superview
            popoverPresentationController.sourceRect = sender.frame
        }
        present(alertViewController, animated: true)
    }
}
