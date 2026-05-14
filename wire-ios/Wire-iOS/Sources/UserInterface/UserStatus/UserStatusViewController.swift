//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

    weak var delegate: UserStatusViewControllerDelegate?

    private lazy var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    private let viewModel: UserStatusViewModel

    var userStatus = UserStatus() {
        didSet {
            viewModel.userStatus = userStatus
            applyDisplayModel()
        }
    }

    init(
        options: UserStatusView.Options,
        settings: Settings
    ) {
        self.viewModel = UserStatusViewModel(options: options, settings: settings)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let displayModel = viewModel.displayModel
        let view = UserStatusView(options: displayModel.options)
        view.userStatus = displayModel.userStatus
        view.tapHandler = { [weak self] button in
            self?.presentAvailabilityPicker(button)
        }
        self.view = view
    }

    private func presentAvailabilityPicker(_ sender: UIButton) {
        let availabilityChangedHandler = { [weak self] (availability: Availability) in
            guard let self else { return }

            handle(viewModel.selectAvailability(availability))
        }

        let alertViewController = UIAlertController.availabilityPicker(availabilityChangedHandler)
        if let popoverPresentationController = alertViewController.popoverPresentationController {
            popoverPresentationController.sourceView = sender.superview
            popoverPresentationController.sourceRect = sender.frame
        }
        present(alertViewController, animated: true)
    }

    private func applyDisplayModel() {
        applyDisplayModel(viewModel.displayModel)
    }

    private func applyDisplayModel(_ displayModel: UserStatusViewModel.DisplayModel) {
        (viewIfLoaded as? UserStatusView)?.userStatus = displayModel.userStatus
    }

    private func handle(_ selection: UserStatusViewModel.Selection) {
        applyDisplayModel(selection.displayModel)

        selection.actions.forEach { action in
            switch action {
            case let .notifyAvailabilityChanged(availability):
                userStatus = selection.displayModel.userStatus
                delegate?.userStatusViewController(self, didSelect: availability)

            case .playSelectionFeedback:
                feedbackGenerator.impactOccurred()

            case let .showAvailabilityExplanation(availability):
                present(UIAlertController.availabilityExplanation(availability), animated: true)
            }
        }
    }
}
