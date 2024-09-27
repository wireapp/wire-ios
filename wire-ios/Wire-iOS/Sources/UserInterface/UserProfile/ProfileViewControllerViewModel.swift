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
import WireSyncEngine
import WireSystem

// MARK: - ProfileViewControllerContext

enum ProfileViewControllerContext {
    case search
    case groupConversation
    case oneToOneConversation
    case deviceList
    /// when opening from a URL scheme, not linked to a specific conversation
    case profileViewer
}

// MARK: - ProfileViewControllerViewModeling

// sourcery: AutoMockable
protocol ProfileViewControllerViewModeling {
    var classification: SecurityClassification? { get }
    var userSet: UserSet { get }
    var userSession: UserSession { get }
    var user: UserType { get }
    var viewer: UserType { get }
    var conversation: ZMConversation? { get }
    var context: ProfileViewControllerContext { get }
    var hasUserClientListTab: Bool { get }
    var blockTitle: String? { get }
    var allBlockResult: [BlockResult] { get }
    var hasLegalHoldItem: Bool { get }
    var incomingRequestFooterHidden: Bool { get }

    func updateActionsList()
    func sendConnectionRequest()
    func acceptConnectionRequest()
    func ignoreConnectionRequest()
    // TODO: [WPB-9028]
    func cancelConnectionRequest(completion: @escaping Completion)
    func openOneToOneConversation()
    func startOneToOneConversation()
    func archiveConversation()
    func updateMute(enableNotifications: Bool)
    func handleNotificationResult(_ result: NotificationResult)
    func handleBlockAndUnblock()
    func handleDeleteResult(_ result: ClearContentResult)
    func transitionToListAndEnqueue(leftViewControllerRevealed: Bool, _ block: @escaping () -> Void)
    func setConversationTransitionClosure(_ closure: @escaping (ZMConversation) -> Void)
    func setDelegate(_ delegate: ProfileViewControllerViewModelDelegate)
}

// MARK: - ProfileViewControllerViewModel

final class ProfileViewControllerViewModel: NSObject, ProfileViewControllerViewModeling {
    // MARK: Lifecycle

    init(
        user: UserType,
        conversation: ZMConversation?,
        viewer: UserType,
        context: ProfileViewControllerContext,
        classificationProvider: SecurityClassificationProviding? = ZMUserSession.shared(),
        userSession: UserSession,
        profileActionsFactory: ProfileActionsFactoryProtocol
    ) {
        self.user = user
        self.conversation = conversation
        self.viewer = viewer
        self.context = context
        self.classificationProvider = classificationProvider
        self.userSession = userSession
        self.profileActionsFactory = profileActionsFactory

        super.init()

        self.observerToken = userSession.addUserObserver(self, for: user)
    }

    // MARK: Internal

    // MARK: - Properties

    let user: UserType
    let conversation: ZMConversation?
    let viewer: UserType
    let context: ProfileViewControllerContext
    let userSession: UserSession

    // MARK: - Computed Properties

    var classification: SecurityClassification? {
        classificationProvider?.classification(users: [user], conversationDomain: nil) ?? .none
    }

    var hasLegalHoldItem: Bool {
        user.isUnderLegalHold || conversation?.isUnderLegalHold == true
    }

    var hasUserClientListTab: Bool {
        context != .search &&
            context != .profileViewer
    }

    var userSet: UserSet {
        UserSet(arrayLiteral: user)
    }

    var incomingRequestFooterHidden: Bool {
        !user.isPendingApprovalBySelfUser
    }

    var blockTitle: String? {
        BlockResult.title(for: user)
    }

    var allBlockResult: [BlockResult] {
        BlockResult.all(isBlocked: user.isBlocked)
    }

    // MARK: - Delegate

    func setDelegate(_ delegate: any ProfileViewControllerViewModelDelegate) {
        viewModelDelegate = delegate
    }

    // MARK: - Blocking

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

    func handleBlockAndUnblock() {
        switch context {
        case .search:
            // Stay on this VC and let user to decise what to do next
            enqueueChanges(toggleBlocked)
        default:
            transitionToListAndEnqueue { self.toggleBlocked() }
        }
    }

    // MARK: - Opening Conversation

    func openOneToOneConversation() {
        if let conversation = user.oneToOneConversation {
            transition(to: conversation)
        } else {
            startOneToOneConversation()
        }
    }

    func startOneToOneConversation() {
        viewModelDelegate?.startAnimatingActivity()

        userSession.createTeamOneOnOne(with: user) { [weak self] in
            self?.viewModelDelegate?.stopAnimatingActivity()

            switch $0 {
            case let .success(conversation):
                self?.transition(to: conversation)
            case let .failure(error):
                WireLogger.conversation.warn("failed to create team one on one from profile view: \(error)")
                guard let username = self?.user.name else {
                    return
                }
                self?.viewModelDelegate?.presentConversationCreationError(username: username)
            }
        }
    }

    // MARK: - Actions List

    func updateActionsList() {
        profileActionsFactory.makeActionsList(completion: { actions in
            self.viewModelDelegate?.updateFooterActionsViews(actions)
        })
    }

    func archiveConversation() {
        transitionToListAndEnqueue {
            self.conversation?.isArchived.toggle()
        }
    }

    // MARK: - Mute

    func updateMute(enableNotifications: Bool) {
        userSession.enqueue {
            self.conversation?.mutedMessageTypes = enableNotifications ? .none : .all
            // update the footer view to display the correct mute/unmute button
            self.updateActionsList()
        }
    }

    // MARK: - Notifications

    func handleNotificationResult(_ result: NotificationResult) {
        if let mutedMessageTypes = result.mutedMessageTypes {
            userSession.perform {
                self.conversation?.mutedMessageTypes = mutedMessageTypes
            }
        }
    }

    // MARK: - Deletion

    func handleDeleteResult(_ result: ClearContentResult) {
        guard case let .delete(leave: leave) = result else {
            return
        }
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

    // MARK: - Transition

    func transitionToListAndEnqueue(leftViewControllerRevealed: Bool = true, _ block: @escaping () -> Void) {
        ZClientViewController.shared?.transitionToList(
            animated: true,
            leftViewControllerRevealed: leftViewControllerRevealed
        ) {
            self.enqueueChanges(block)
        }
    }

    func setConversationTransitionClosure(_ closure: @escaping (ZMConversation) -> Void) {
        conversationTransitionClosure = closure
    }

    // MARK: Connect

    func sendConnectionRequest() {
        user.connect { [weak self] error in
            if let error = error as? ConnectToUserError {
                self?.viewModelDelegate?.presentError(error)
            }
            self?.updateActionsList()
        }
    }

    func acceptConnectionRequest() {
        user.accept { [weak self] error in
            if let error = error as? LocalizedError {
                self?.viewModelDelegate?.presentError(error)
            } else {
                self?.user.refreshData()
                self?.updateActionsList()
                self?.viewModelDelegate?.updateIncomingRequestFooter()
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

    func cancelConnectionRequest(completion: @escaping Completion) {
        user.cancelConnectionRequest { [weak self] error in
            if let error = error as? ConnectToUserError {
                self?.viewModelDelegate?.presentError(error)
            } else {
                completion()
            }
        }
    }

    // MARK: Private

    private weak var viewModelDelegate: ProfileViewControllerViewModelDelegate?

    private var observerToken: NSObjectProtocol?
    private let profileActionsFactory: ProfileActionsFactoryProtocol
    private let classificationProvider: SecurityClassificationProviding?
    private var conversationTransitionClosure: ((ZMConversation) -> Void)?

    // MARK: - Helpers

    private func enqueueChanges(_ block: @escaping () -> Void) {
        userSession.enqueue(block)
    }

    private func transition(to conversation: ZMConversation) {
        conversationTransitionClosure?(conversation)
    }
}

// MARK: UserObserving

extension ProfileViewControllerViewModel: UserObserving {
    // MARK: - User Changes

    func userDidChange(_ note: UserChangeInfo) {
        if note.legalHoldStatusChanged {
            viewModelDelegate?.setupNavigationItems()
        }

        if note.user.isAccountDeleted || note.connectionStateChanged {
            updateActionsList()
            viewModelDelegate?.updateIncomingRequestFooter()
        }
    }
}

// MARK: - ProfileViewControllerViewModelDelegate

// sourcery: AutoMockable
protocol ProfileViewControllerViewModelDelegate: AnyObject {
    func setupNavigationItems()
    func updateFooterActionsViews(_ actions: [ProfileAction])
    func updateIncomingRequestFooter()
    func returnToPreviousScreen()
    func presentError(_ error: LocalizedError)
    func presentConversationCreationError(username: String)
    func startAnimatingActivity()
    func stopAnimatingActivity()
}
