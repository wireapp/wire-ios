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
import WireDesign
import WireSyncEngine

final class RemoveClientStepViewController: UIViewController, AuthenticationCoordinatedViewController {

    var authenticationCoordinator: AuthenticationCoordinator?
    let clientListController: RemoveClientsViewController
    private let viewModel: RemoveClientStepViewModel
    var userInterfaceSizeClass: (UITraitEnvironment) -> UIUserInterfaceSizeClass = { traitEnvironment in
        traitEnvironment.traitCollection.horizontalSizeClass
    }

    private var contentViewWidthRegular: NSLayoutConstraint!
    private var contentViewWidthCompact: NSLayoutConstraint!

    // MARK: - Initialization

    init(clients: [UserClient]) {
        self.clientListController = RemoveClientsViewController(clientsList: clients)
        self.viewModel = RemoveClientStepViewModel()

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configureConstraints()
        render(viewModel.displayState(canCancel: canCancel))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarTitle(viewModel.displayState(canCancel: canCancel).navigationTitle)
    }

    private func configureSubviews() {
        view.backgroundColor = SemanticColors.View.backgroundDefault

        clientListController.view.backgroundColor = .clear
        clientListController.delegate = self
        addToSelf(clientListController)
    }

    private func configureConstraints() {
        clientListController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            clientListController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clientListController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            clientListController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let displayState = viewModel.displayState(canCancel: canCancel)
        contentViewWidthRegular = clientListController.view.widthAnchor.constraint(
            equalToConstant: displayState.regularContentWidth
        )
        contentViewWidthCompact = clientListController.view.widthAnchor.constraint(equalTo: view.widthAnchor)

        toggleConstraints()
    }

    private var canCancel: Bool {
        guard let count = navigationController?.viewControllers.count else {
            return false
        }
        return count > 1
    }

    private func render(_ displayState: RemoveClientStepViewModel.DisplayState) {
        setupNavigationBarTitle(displayState.navigationTitle)
        updateBackButton(
            isVisible: displayState.showsCancelButton,
            isEnabled: displayState.isCancelButtonEnabled
        )
    }

    // MARK: - Back Button

    private func updateBackButton(isVisible: Bool, isEnabled: Bool) {
        guard isVisible else {
            navigationItem.leftBarButtonItem = nil
            return
        }

        let button = AuthenticationNavigationBar.makeBackButton()
        button.isEnabled = isEnabled
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }

    @objc
    private func backButtonTapped() {
        handle(route: viewModel.routeForCancelTapped())
    }

    // MARK: - Adaptive UI

    func toggleConstraints() {
        userInterfaceSizeClass(self).toggle(
            compactConstraints: [contentViewWidthCompact],
            regularConstraints: [contentViewWidthRegular]
        )
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        toggleConstraints()
    }

    // MARK: - AuthenticationCoordinatedViewController

    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        // no-op
    }

    func displayError(_ error: Error) {
        // no-op
    }

    func didRewindToThisView() {
        // no-op
    }

    private func handle(route: RemoveClientStepViewModel.Route) {
        switch route {
        case .cancel:
            navigationController?.popViewController(animated: true)
        }
    }

    private func handle(action: RemoveClientStepViewModel.Action) {
        switch action {
        case .continueAfterRemovingClient:
            authenticationCoordinator?.executeActions([.unwindState(withInterface: true), .showLoadingView])

        case let .showRemovalError(error):
            let alert = AuthenticationCoordinatorErrorAlert(
                error: error as NSError,
                completionActions: [.unwindState(withInterface: false)]
            )
            authenticationCoordinator?.executeActions([.hideLoadingView, .presentErrorAlert(alert)])
        }
    }
}

// MARK: - ClientListViewControllerDelegate

extension RemoveClientStepViewController: RemoveClientsViewControllerDelegate {

    func finishedDeleting(_ clientListViewController: RemoveClientsViewController) {
        handle(action: viewModel.actionForFinishedDeleting())
    }

    func failedToDeleteClients(_ error: Error) {
        handle(action: viewModel.actionForFailedToDeleteClients(error))
    }

}
