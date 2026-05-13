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
import WireMainNavigationUI
import WireMessagingDomain
import WireReusableUIComponents
import WireSyncEngine

final class SearchUserViewController: UIViewController {

    // MARK: - Properties

    private var searchDirectory: SearchDirectory!
    private weak var profileViewControllerDelegate: ProfileViewControllerDelegate?
    private let qualifiedID: QualifiedID
    private var pendingSearchTask: SearchTask?
    private let userSession: UserSession
    private let mainCoordinator: AnyMainCoordinator
    private let selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    private let conversationCreationRepository: any ConversationCreationRepositoryProtocol
    private var viewModel = SearchUserViewModel()

    private lazy var activityIndicator = BlockingActivityIndicator(view: view)

    // MARK: - Init

    init(
        qualifiedID: QualifiedID,
        profileViewControllerDelegate: ProfileViewControllerDelegate?,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        conversationCreationRepository: any ConversationCreationRepositoryProtocol
    ) {
        self.qualifiedID = qualifiedID
        self.profileViewControllerDelegate = profileViewControllerDelegate
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.selfProfileUIBuilder = selfProfileUIBuilder
        self.conversationCreationRepository = conversationCreationRepository

        super.init(nibName: nil, bundle: nil)

        if let session = userSession as? ZMUserSession,
           let searchAPI = session.clientSessionComponent?.searchAPI,
           let teamsAPI = session.clientSessionComponent?.teamsAPI,
           let usersAPI = session.clientSessionComponent?.usersAPI {
            self.searchDirectory = SearchDirectory(
                userSession: session,
                searchAPI: searchAPI,
                teamsAPI: teamsAPI,
                usersAPI: usersAPI
            )
        }

        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        searchDirectory?.tearDown()
    }

    // MARK: - Override Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.start()
        startLookup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let closeItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.pendingSearchTask?.cancel()
            self?.pendingSearchTask = nil
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: viewModel.closeButtonAccessibilityLabel)

        navigationItem.rightBarButtonItem = closeItem
    }

    // MARK: - Methods

    private func startLookup() {
        guard let searchDirectory else { return }

        Task {
            let task = searchDirectory.createLookupTask(with: qualifiedID)
            pendingSearchTask = task
            let searchResult = await task.start()
            pendingSearchTask = nil
            activityIndicator.stop()
            handleSearchResult(searchResult: searchResult)
        }
    }

    private func handleSearchResult(searchResult: SearchResult) {
        switch viewModel.action(for: searchResult, viewer: ZMUser.selfUser()) {
        case let .showProfile(route):
            showProfile(route)
        case let .showInvalidUser(alertContent):
            showInvalidUserAlert(alertContent)
        case let .assertMissingSelfUser(message):
            assertionFailure(message)
        case .ignore:
            break
        }
    }

    private func showProfile(_ route: SearchUserViewModel.ProfileRoute) {
        let profileViewController = ProfileViewController(
            user: route.user,
            viewer: route.viewer,
            context: .profileViewer,
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileUIBuilder,
            conversationCreationRepository: conversationCreationRepository
        )
        profileViewController.delegate = profileViewControllerDelegate

        navigationController?.setViewControllers([profileViewController], animated: true)
    }

    private func showInvalidUserAlert(_ alertContent: SearchUserViewModel.AlertContent) {
        let alert = UIAlertController(
            title: alertContent.title,
            message: alertContent.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: alertContent.buttonTitle,
            style: .cancel,
            handler: { [weak self] _ in
                self?.dismiss(animated: true)
            }
        ))

        present(alert, animated: true)
    }
}
