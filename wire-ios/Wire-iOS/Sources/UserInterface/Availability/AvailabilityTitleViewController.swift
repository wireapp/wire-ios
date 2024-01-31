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

import Foundation
import UIKit
import WireDataModel
import WireSyncEngine

final class AvailabilityTitleViewController: UIViewController {

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let options: AvailabilityTitleView.Options
    private let user: UserType
    let userSession: UserSession

    var availabilityTitleView: AvailabilityTitleView? {
        return view as? AvailabilityTitleView
    }

    init(user: UserType, options: AvailabilityTitleView.Options, userSession: UserSession) {
        self.user = user
        self.options = options
        self.userSession = userSession
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = AvailabilityTitleView(user: user, options: options, userSession: userSession)
    }

    override func viewDidLoad() {
        availabilityTitleView?.tapHandler = { [weak self] _ in
            guard let `self` = self else { return }
            self.presentAvailabilityPicker()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            availabilityTitleView?.updateConfiguration()
        }
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
            self?.provideHapticFeedback()
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

}
