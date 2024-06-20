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
import WireDesign
import WireSyncEngine

final class SearchUserViewController: UIViewController, SpinnerCapable {

    // MARK: - Properties

    var dismissSpinner: (() -> Void)?

    private var searchDirectory: SearchDirectory!
    private weak var profileViewControllerDelegate: ProfileViewControllerDelegate?
    private let userId: UUID
    private var pendingSearchTask: SearchTask?
    private let userSession: UserSession

    /// flag for handleSearchResult. Only allow to display the result once
    private var resultHandled = false

    // MARK: - Init

    init(userId: UUID, profileViewControllerDelegate: ProfileViewControllerDelegate?, userSession: UserSession) {
        self.userId = userId
        self.profileViewControllerDelegate = profileViewControllerDelegate
        self.userSession = userSession

        super.init(nibName: nil, bundle: nil)

        if let session = ZMUserSession.shared() {
            searchDirectory = SearchDirectory(userSession: session)
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

        let cancelItem = UIBarButtonItem(icon: .cross, target: self, action: #selector(cancelButtonTapped))
        cancelItem.accessibilityIdentifier = "CancelButton"
        cancelItem.accessibilityLabel = L10n.Localizable.General.cancel
        navigationItem.rightBarButtonItem = cancelItem

        isLoadingViewVisible = true

        if let task = searchDirectory?.lookup(userId: userId) {
            task.addResultHandler({ [weak self] in
                self?.handleSearchResult(searchResult: $0, isCompleted: $1)
            })
            task.start()

            pendingSearchTask = task
        }

    }

    // MARK: - Methods

    private func handleSearchResult(searchResult: SearchResult, isCompleted: Bool) {
        guard !resultHandled, isCompleted else { return }
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        let profileUser: UserType?
        if let searchUser = searchResult.directory.first, !searchUser.isAccountDeleted {
            profileUser = searchUser
        } else if let memberUser = searchResult.teamMembers.first?.user, !memberUser.isAccountDeleted {
            profileUser = memberUser
        } else {
            profileUser = nil
        }

        if let profileUser {
            let profileViewController = ProfileViewController(
                user: profileUser,
                viewer: selfUser,
                context: .profileViewer,
                userSession: userSession
            )
            profileViewController.delegate = profileViewControllerDelegate

            navigationController?.setViewControllers([profileViewController], animated: true)
            resultHandled = true
        } else if isCompleted {
            let alert = UIAlertController(
                title: L10n.Localizable.UrlAction.InvalidUser.title,
                message: L10n.Localizable.UrlAction.InvalidUser.message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: L10n.Localizable.General.ok,
                style: .cancel,
                handler: { [weak self] _ in
                    self?.dismiss(animated: true)
                }
            ))

            present(alert, animated: true)
        }
    }

    // MARK: - Actions

    @objc private func cancelButtonTapped(sender: AnyObject?) {
        pendingSearchTask?.cancel()
        pendingSearchTask = nil

        dismiss(animated: true)
    }
}
