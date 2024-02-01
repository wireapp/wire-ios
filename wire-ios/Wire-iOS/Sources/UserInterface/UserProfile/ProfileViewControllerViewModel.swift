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

import Foundation
import WireDataModel
import WireSystem
import WireSyncEngine

private let zmLog = ZMSLog(tag: "ProfileViewControllerViewModel")

enum ProfileViewControllerContext {
    case search
    case groupConversation
    case oneToOneConversation
    case deviceList
    /// when opening from a URL scheme, not linked to a specific conversation
    case profileViewer
}

final class ProfileViewControllerViewModel: NSObject {
    let user: UserType
    let conversation: ZMConversation?
    let viewer: UserType
    let context: ProfileViewControllerContext
    let classificationProvider: ClassificationProviding?
    let userSession: UserSession

    weak var delegate: ProfileViewControllerDelegate? {
        didSet {
            backButtonTitleDelegate = delegate as? BackButtonTitleDelegate
        }
    }

    weak var backButtonTitleDelegate: BackButtonTitleDelegate?

    private var observerToken: Any?
    weak var viewModelDelegate: ProfileViewControllerViewModelDelegate?

    init(user: UserType,
         conversation: ZMConversation?,
         viewer: UserType,
         context: ProfileViewControllerContext,
         classificationProvider: ClassificationProviding? = ZMUserSession.shared(),
         userSession: UserSession
    ) {
        self.user = user
        self.conversation = conversation
        self.viewer = viewer
        self.context = context
        self.classificationProvider = classificationProvider
        self.userSession = userSession
        super.init()

        observerToken = userSession.addUserObserver(self, for: user)
    }

    var classification: SecurityClassification {
        classificationProvider?.classification(with: [user], conversationDomain: nil) ?? .none
    }

    var hasLegalHoldItem: Bool {
        return user.isUnderLegalHold || conversation?.isUnderLegalHold == true
    }

    var shouldShowVerifiedShield: Bool {
        return user.isVerified && context != .deviceList
    }

    var hasUserClientListTab: Bool {
        return context != .search &&
            context != .profileViewer
    }

    var userSet: UserSet {
        return UserSet(arrayLiteral: user)
    }

    var incomingRequestFooterHidden: Bool {
        return !user.isPendingApprovalBySelfUser
    }

    var blockTitle: String? {
        return BlockResult.title(for: user)
    }

    var allBlockResult: [BlockResult] {
        return BlockResult.all(isBlocked: user.isBlocked)
    }

    func cancelConnectionRequest(completion: @escaping Completion) {
        self.user.cancelConnectionRequest { [weak self] error in
            if let error = error as? ConnectToUserError {
                self?.viewModelDelegate?.presentError(error)
            } else {
                completion()
            }
        }
    }

    func toggleBlocked() {
        if user.isBlocked {
            user.accept { [weak self] error in
                if let error = error as? LocalizedError {
                    self?.viewModelDelegate?.presentError(error)
                }
            }
        } else {
            user.block { [weak self] error in
                if let error = error as? LocalizedError {
                    self?.viewModelDelegate?.presentError(error)
                }
            }
        }
    }

    func openOneToOneConversation() {
        guard let userSession = ZMUserSession.shared() else { return }

        if let conversation = user.oneToOneConversation {
            transition(to: conversation)
        } else {
            user.createTeamOneToOneConversation(in: userSession.viewContext) { result in
                guard case .success(let conversation) = result else { return }

                self.transition(to: conversation)
            }
        }
    }

    // MARK: - Action Handlers

    func archiveConversation() {
        transitionToListAndEnqueue {
            self.conversation?.isArchived.toggle()
        }
    }

    func handleBlockAndUnblock() {
        switch context {
        case .search:
            // Stay on this VC and let user to decise what to do next
            enqueueChanges(toggleBlocked)
        default:
            transitionToListAndEnqueue { self.toggleBlocked() }
        }
    }

    // MARK: - Notifications

    func updateMute(enableNotifications: Bool) {
        userSession.enqueue {
            self.conversation?.mutedMessageTypes = enableNotifications ? .none : .all
            // update the footer view to display the correct mute/unmute button
            self.viewModelDelegate?.updateFooterViews()
        }
    }

    func handleNotificationResult(_ result: NotificationResult) {
        if let mutedMessageTypes = result.mutedMessageTypes {
            userSession.perform {
                self.conversation?.mutedMessageTypes = mutedMessageTypes
            }
        }
    }

    // MARK: Delete Contents

    func handleDeleteResult(_ result: ClearContentResult) {
        guard case .delete(leave: let leave) = result else { return }
        guard let user = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return
        }

        transitionToListAndEnqueue {
            self.conversation?.clearMessageHistory()
            if leave {
                self.conversation?.removeOrShowError(participant: user)
            }
        }
    }

    // MARK: - Helpers

    func transitionToListAndEnqueue(leftViewControllerRevealed: Bool = true, _ block: @escaping () -> Void) {
        ZClientViewController.shared?.transitionToList(animated: true,
                                                       leftViewControllerRevealed: leftViewControllerRevealed) {
                                                        self.enqueueChanges(block)
        }
    }

    func enqueueChanges(_ block: @escaping () -> Void) {
        userSession.enqueue(block)
    }

    private func transition(to conversation: ZMConversation) {
        delegate?.profileViewController(
            viewModelDelegate as? ProfileViewController,
            wantsToNavigateTo: conversation)
    }

    // MARK: - Factories

    func makeUserNameDetailViewModel() -> UserNameDetailViewModel {
        // TODO: add addressBookEntry to ZMUser
        return UserNameDetailViewModel(user: user, fallbackName: user.name ?? "", addressBookName: (user as? ZMUser)?.addressBookEntry?.cachedName)
    }

    var profileActionsFactory: ProfileActionsFactory {
        return ProfileActionsFactory(user: user, viewer: viewer, conversation: conversation, context: context)
    }

    // MARK: Connect

    func sendConnectionRequest() {
        user.connect { [weak self] error in
            if let error = error as? ConnectToUserError {
                self?.viewModelDelegate?.presentError(error)
            }
            self?.viewModelDelegate?.updateFooterViews()
        }
    }

    func acceptConnectionRequest() {
        user.accept { [weak self] error in
            if let error = error as? LocalizedError {
                self?.viewModelDelegate?.presentError(error)
            } else {
                self?.user.refreshData()
                self?.viewModelDelegate?.updateFooterViews()
            }
        }
    }

    func ignoreConnectionRequest() {
        user.ignore { [weak self] error in
            if let error = error as? ConnectToUserError {
                self?.viewModelDelegate?.presentError(error)
            } else {
                self?.viewModelDelegate?.returnToPreviousScreen()
            }
        }
    }

}

extension ProfileViewControllerViewModel: UserChangeObserver {
    func userDidChange(_ note: UserChangeInfo) {
        if note.trustLevelChanged {
            viewModelDelegate?.updateShowVerifiedShield()
        }

        if note.legalHoldStatusChanged {
            viewModelDelegate?.setupNavigationItems()
        }

        if note.nameChanged {
            viewModelDelegate?.updateTitleView()
        }

        if note.user.isAccountDeleted || note.connectionStateChanged {
            viewModelDelegate?.updateFooterViews()
        }
    }
}

extension ProfileViewControllerViewModel: BackButtonTitleDelegate {
    func suggestedBackButtonTitle(for controller: ProfileViewController?) -> String? {
        return user.name?.uppercasedWithCurrentLocale
    }
}

protocol ProfileViewControllerViewModelDelegate: AnyObject {
    func updateShowVerifiedShield()
    func setupNavigationItems()
    func updateFooterViews()
    func updateTitleView()
    func returnToPreviousScreen()
    func presentError(_ error: LocalizedError)
}
