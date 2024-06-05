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
import WireSyncEngine
import WireSystem

final class StartUIView: UIView { }

extension StartUIViewController {
    private func presentProfileViewController(for bareUser: UserType,
                                              at indexPath: IndexPath?) {
        _ = searchHeaderViewController.tokenField.resignFirstResponder()

        guard let indexPath,
            let cell = searchResultsViewController.searchResultsView.collectionView.cellForItem(at: indexPath) else { return }

        profilePresenter.presentProfileViewController(for: bareUser, in: self, from: view.convert(cell.bounds, from: cell), userSession: userSession, onDismiss: {
            if self.isIPadRegular() {
                let indexPaths = self.searchResultsViewController.searchResultsView.collectionView.indexPathsForVisibleItems
                self.searchResultsViewController.searchResultsView.collectionView.reloadItems(at: indexPaths)
            } else if self.profilePresenter.keyboardPersistedAfterOpeningProfile {
                    _ = self.searchHeaderViewController.tokenField.becomeFirstResponder()
                    self.profilePresenter.keyboardPersistedAfterOpeningProfile = false
            }
        })
    }
}

extension StartUIViewController: SearchResultsViewControllerDelegate {

    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController,
                                     didTapOnUser user: UserType,
                                     indexPath: IndexPath,
                                     section: SearchResultsViewControllerSection) {

        if !user.isConnected && !user.isTeamMember {
            presentProfileViewController(for: user, at: indexPath)
        } else {
            delegate?.startUI(self, didSelect: user)
        }
    }

    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController,
                                     didDoubleTapOnUser user: UserType,
                                     indexPath: IndexPath) {

        guard user.isConnected, !user.isBlocked else {
            return
        }

        delegate?.startUI(self, didSelect: user)
    }

    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController,
                                     didTapOnConversation conversation: ZMConversation) {
        guard conversation.conversationType == .group || conversation.conversationType == .oneOnOne else { return }

        delegate?.startUI(self, didSelect: conversation)
    }

    func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController,
                                     didTapOnSeviceUser user: ServiceUser) {

        let detail = ServiceDetailViewController(
            serviceUser: user,
            actionType: .openConversation,
            userSession: userSession
        ) { [weak self] result in
            guard let self else { return }

            if let result {
                switch result {
                case .success(let conversation):
                    delegate?.startUI(self, didSelect: conversation)
                case .failure(let error):
                    error.displayAddBotError(in: self)
                }
            } else {
                navigationController?.dismiss(animated: true, completion: nil)
            }
        }

        navigationController?.pushViewController(detail, animated: true)
    }

    func openCreateGroupController() {
        let controller = ConversationCreationController(preSelectedParticipants: nil, userSession: userSession)
        controller.delegate = self

        if self.traitCollection.horizontalSizeClass == .compact {
            let avoiding = KeyboardAvoidingViewController(viewController: controller)
            navigationItem.backBarButtonItem?.accessibilityLabel = L10n.Accessibility.CreateConversation.BackButton.description
            self.navigationController?.pushViewController(avoiding, animated: true) {
            }
        } else {
            let embeddedNavigationController = controller.wrapInNavigationController()
            embeddedNavigationController.modalPresentationStyle = .formSheet
            self.present(embeddedNavigationController, animated: true)
        }
    }
}

extension StartUIViewController: ConversationCreationControllerDelegate {

    func conversationCreationController(
        _ controller: ConversationCreationController,
        didCreateConversation conversation: ZMConversation
    ) {
        dismiss(controller: controller) { [weak self] in
            guard let self else { return }

            delegate?.startUI(
                self,
                didSelect: conversation
            )
        }
    }

    func dismiss(
        controller: ConversationCreationController,
        completion: (() -> Void)? = nil
    ) {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            navigationController?.popToRootViewController(
                animated: true,
                completion: completion
            )

        default:
            controller.navigationController?.dismiss(
                animated: true,
                completion: completion
            )
        }
    }

}

extension StartUIViewController: EmptySearchResultsViewDelegate {
    func execute(action: EmptySearchResultsViewAction, from: EmptySearchResultsView) {
        switch action {
        case .openManageServices:
            URL.manageTeam(source: .onboarding).openInApp(above: self)
        case .openSearchSupportPage:
            URL.wr_searchSupport.open()
        }
    }
}
