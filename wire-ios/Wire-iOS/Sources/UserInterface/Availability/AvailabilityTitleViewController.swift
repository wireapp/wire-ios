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

final class AvailabilityTitleViewController: UIViewController {

    private lazy var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    private let options: AvailabilityTitleView.Options
    private let user: UserType
    private let userSession: UserSession
    private let getSelfUserVerificationStatusUseCase: GetSelfUserVerificationStatusUseCaseProtocol

    init(
        user: UserType,
        options: AvailabilityTitleView.Options,
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
        let view = AvailabilityTitleView(
            user: user,
            options: options,
            userSession: userSession,
            getSelfUserVerificationStatusUseCase: getSelfUserVerificationStatusUseCase
        )
        view.tapHandler = { [weak self] _ in self?.presentAvailabilityPicker() }
        self.view = view
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            (view as! AvailabilityTitleView).updateConfiguration()
        }
    }

    private func presentAvailabilityPicker() {
        let alertViewController = UIAlertController.availabilityPicker { [weak self] availability in
            self?.didSelectAvailability(availability)
        }
        alertViewController.configPopover(pointToView: view)
        present(alertViewController, animated: true)
    }

    private func didSelectAvailability(_ availability: AvailabilityKind) {
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
