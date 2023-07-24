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
import WireDataModel
import UIKit
import WireSyncEngine

private typealias ConversationCreatedBlock = (ZMConversation?) -> Void

extension ConversationListViewController.ViewModel: StartUIDelegate {
    func startUI(_ startUI: StartUIViewController, didSelect user: UserType) {
        oneToOneConversationWithUser(user, callback: { conversation in
            guard let conversation = conversation else { return }

            ZClientViewController.shared?.select(conversation: conversation, focusOnView: true, animated: true)
        })
    }

    func startUI(_ startUI: StartUIViewController, didSelect conversation: ZMConversation) {
        startUI.dismissIfNeeded(animated: true) {
            ZClientViewController.shared?.select(conversation: conversation, focusOnView: true, animated: true)
        }
    }

    func startUI(
        _ startUI: StartUIViewController,
        createConversationWith users: UserSet,
        name: String,
        allowGuests: Bool,
        allowServices: Bool,
        enableReceipts: Bool,
        encryptionProtocol: EncryptionProtocol,
        onCompletion: @escaping (_ postCompletionAction: @escaping () -> Void) -> Void
    ) {
        guard let viewController = viewController as? UIViewController else { return }
        let initialized = conversationCreationCoordinator.initialize { [weak self] result in
            onCompletion {
                switch result {
                case .success(let conversation):
                    viewController.dismissIfNeeded {
                        delay(0.3) {
                            ZClientViewController.shared?.select(
                                conversation: conversation,
                                focusOnView: true,
                                animated: true
                            )
                        }
                    }
                case .failure:
                    viewController.dismissIfNeeded()
                }
                self?.conversationCreationCoordinator.finalize()
            }
        }
        guard initialized else { return }
        let creatingConversation = conversationCreationCoordinator.createConversation(
            withUsers: users,
            name: name,
            allowGuests: allowGuests,
            allowServices: allowServices,
            enableReceipts: enableReceipts,
            encryptionProtocol: encryptionProtocol)
        guard creatingConversation else {
            conversationCreationCoordinator.finalize()
            return
        }
    }

    /// Create a new conversation or open existing 1-to-1 conversation
    ///
    /// - Parameters:
    ///   - user: the user which we want to have a 1-to-1 conversation with
    ///   - onConversationCreated: a ConversationCreatedBlock which has the conversation created
    private func oneToOneConversationWithUser(_ user: UserType, callback onConversationCreated: @escaping ConversationCreatedBlock) {

        guard let userSession = ZMUserSession.shared() else { return }

        viewController?.setState(.conversationList, animated: true) {
            var oneToOneConversation: ZMConversation?
            userSession.enqueue({
                oneToOneConversation = user.oneToOneConversation
            }, completionHandler: {
                delay(0.3) {
                    onConversationCreated(oneToOneConversation)
                }
            })
        }
    }
}

enum GroupConversationCreationResult {
    enum FailureType {
        case missingLegalHoldConsent
        case nonFederatingBackends
        case other
    }
    case success(conversation: ZMConversation)
    case failure(failureType: FailureType)
}

class GroupConversationCreationCoordinator {
    private enum State {
        case ready
        case initializing
        case initialized(completionHandler: (GroupConversationCreationResult) -> Void)
        case beginingToCreateConversation(completionHandler: (GroupConversationCreationResult) -> Void)
        case creatingConversation(conversation: ZMConversation, completionHandler: (GroupConversationCreationResult) -> Void)
        case finalizing
    }
    private var state: State = .ready

    private var conversation: ZMConversation? {
        guard case .creatingConversation(let conversation, _) = state else { return nil }
        return conversation
    }

    private var completionHandler: ((GroupConversationCreationResult) -> Void)? {
        switch state {
        case .creatingConversation(_, let completionHandler), .initialized(let completionHandler), .beginingToCreateConversation(let completionHandler):
            return completionHandler
        case .ready, .finalizing, .initializing:
            return nil
        }
    }

    func initialize(completionHandler: @escaping (GroupConversationCreationResult) -> Void) -> Bool {
        guard case .ready = state else { return false }
        NotificationCenter.default.addObserver(self, selector: #selector(missingLegalConsentErrorHandler), name: ZMConversation.missingLegalHoldConsentNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nonFederatingBackendsErrorHandler), name: ZMConversation.nonFederatingBackendsNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unsupportedErrorsHandler), name: ZMConversation.unknownResponseErrorNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(conversationCreatedHandler), name: ZMConversation.insertedConversationUpdatedNotificationName, object: nil)
        state = .initialized(completionHandler: completionHandler)
        return true
    }

    func createConversation(
        withUsers users: UserSet?,
        name: String?,
        allowGuests: Bool,
        allowServices: Bool,
        enableReceipts: Bool,
        encryptionProtocol: EncryptionProtocol
     ) -> Bool {
         guard case .initialized(let completionHandler) = state else { return false }
         guard
             let users = users,
             let userSession = ZMUserSession.shared()
         else {
             return false
         }
         state = .beginingToCreateConversation(completionHandler: completionHandler)

         var conversation: ZMConversation?

         userSession.enqueue {
             conversation = ZMConversation.insertGroupConversation(
                 moc: userSession.viewContext,
                 participants: users.materialize(in: userSession.viewContext),
                 name: name,
                 team: ZMUser.selfUser().team,
                 allowGuests: allowGuests,
                 allowServices: allowServices,
                 readReceipts: enableReceipts,
                 messageProtocol: encryptionProtocol == .mls ? .mls : .proteus
             )
         } completionHandler: { [weak self] in
             guard let self = self, let conversation = conversation else { return }
             self.state = .creatingConversation(conversation: conversation, completionHandler: completionHandler)
         }

         return true
    }

    func finalize() {
        state = .finalizing
        NotificationCenter.default.removeObserver(self, name: ZMConversation.missingLegalHoldConsentNotificationName, object: nil)
        NotificationCenter.default.removeObserver(self, name: ZMConversation.nonFederatingBackendsNotificationName, object: nil)
        NotificationCenter.default.removeObserver(self, name: ZMConversation.unknownResponseErrorNotificationName, object: nil)
        NotificationCenter.default.removeObserver(self, name: ZMConversation.insertedConversationUpdatedNotificationName, object: nil)
        state = .ready
    }

    @objc func conversationCreatedHandler(notification: Notification) {
        guard let conversation = extractConversation(notification: notification)
            else { return }
        completionHandler?(.success(conversation: conversation))
    }

    @objc func unsupportedErrorsHandler(notification: Notification) {
        guard extractConversation(notification: notification) != nil
            else { return }
        completionHandler?(.failure(failureType: .other))
    }

    @objc func missingLegalConsentErrorHandler(notification: Notification) {
        guard extractConversation(notification: notification) != nil
            else { return }
        typealias ConversationError = L10n.Localizable.Error.Conversation
        UIAlertController.showErrorAlert(
            title: ConversationError.title,
            message: ConversationError.missingLegalholdConsent,
            completion: { [weak self] _ in
                self?.completionHandler?(.failure(failureType: .missingLegalHoldConsent))
            }
        )
    }

    @objc func nonFederatingBackendsErrorHandler(notification: Notification) {
            guard extractConversation(notification: notification) != nil
                else { return }
        guard let userInfo = notification.userInfo,
              userInfo.keys.contains(ZMConversation.UserInfoKeys.nonFederatingBackends.rawValue),
              let nonFederatingBackends = userInfo[ZMConversation.UserInfoKeys.nonFederatingBackends.rawValue] as? NonFederatingBackendsTuple
            else { return }
        let alert = UIAlertController.notFullyConnectedGraphAlert(
            backends: nonFederatingBackends,
            completion: { [weak self] action in
                switch action {
                case .editParticipantsList:
                    self?.finalize()
                case .discardGroupCreation:
                    self?.completionHandler?(.failure(failureType: .nonFederatingBackends))
                case .learnMore:
                    self?.finalize()
                }
            }
        )
        alert.presentTopmost()
    }

    private func extractConversation(notification: Notification) -> ZMConversation? {
        guard
            let userInfo = notification.userInfo,
            userInfo.keys.contains(NotificationInContext.objectInNotificationKey),
            let notificationConversation = userInfo[NotificationInContext.objectInNotificationKey] as? ZMConversation,
            let conversation = self.conversation,
            conversation.objectID == notificationConversation.objectID
        else { return nil }
        return conversation
    }
}

enum NonFullyConnectedGraphAction {
    case editParticipantsList
    case discardGroupCreation
    case learnMore
}

extension UIAlertController {
    static func notFullyConnectedGraphAlert(backends: NonFederatingBackendsTuple, completion: @escaping (NonFullyConnectedGraphAction) -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: "Group can’t be created",
            message: "People from backends \(backends.backendA) and \(backends.backendB) can’t join the same group conversation.\nTo create the group, remove affected participants.", preferredStyle: .alert)
        let editParticipantsAction = UIAlertAction(
            title: "Edit Participants List",
            style: .default,
            handler: { _ in completion(.editParticipantsList) }
        )
        let discardGroupCreationAction = UIAlertAction(
            title: "Discard Group Creation",
            style: .default,
            handler: { _ in completion(.discardGroupCreation) }
        )
        let learnMoreAction = UIAlertAction(
            title: "Learn More",
            style: .default,
            handler: { _ in completion(.learnMore) }
        )
        alert.addAction(editParticipantsAction)
        alert.addAction(discardGroupCreationAction)
        alert.addAction(learnMoreAction)
        alert.preferredAction = editParticipantsAction
        return alert
    }
}
