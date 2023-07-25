//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

class GroupConversationCreationCoordinator {
    private enum State {
        case ready
        case initializing
        case initialized(eventHandler: (GroupConversationCreationEvent) -> Void)
        case beginingToCreateConversation(eventHandler: (GroupConversationCreationEvent) -> Void)
        case creatingConversation(conversation: ZMConversation, eventHandler: (GroupConversationCreationEvent) -> Void)
        case finalizing
    }
    private var state: State = .ready

    private var conversation: ZMConversation? {
        guard case .creatingConversation(let conversation, _) = state else { return nil }
        return conversation
    }

    private var eventHandler: ((GroupConversationCreationEvent) -> Void)? {
        switch state {
        case .creatingConversation(_, let completionHandler), .initialized(let completionHandler), .beginingToCreateConversation(let completionHandler):
            return completionHandler
        case .ready, .finalizing, .initializing:
            return nil
        }
    }

    func initialize(eventHandler: @escaping (GroupConversationCreationEvent) -> Void) -> Bool {
        guard case .ready = state else { return false }
        state = .initializing
        NotificationCenter.default.addObserver(self, selector: #selector(missingLegalConsentErrorHandler), name: ZMConversation.missingLegalHoldConsentNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nonFederatingBackendsErrorHandler), name: ZMConversation.nonFederatingBackendsNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unsupportedErrorsHandler), name: ZMConversation.unknownResponseErrorNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(conversationCreatedHandler), name: ZMConversation.insertedConversationUpdatedNotificationName, object: nil)
        state = .initialized(eventHandler: eventHandler)
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
         guard case .initialized(let eventHandler) = state else { return false }
         guard
             let users = users,
             let userSession = ZMUserSession.shared()
         else {
             return false
         }
         state = .beginingToCreateConversation(eventHandler: eventHandler)
         eventHandler(.showLoader)

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
             self.state = .creatingConversation(conversation: conversation, eventHandler: eventHandler)
         }

         return true
    }

    func createConversation(
        withParticipants users: UserSet,
        name: String?
     ) -> Bool {
         guard case .initialized(let eventHandler) = state else { return false }
         guard let userSession = ZMUserSession.shared() else { return false }
         state = .beginingToCreateConversation(eventHandler: eventHandler)

         var conversation: ZMConversation?

         userSession.enqueue {
             conversation = ZMConversation.insertGroupConversation(session: userSession,
                                                                   participants: Array(users),
                                                                   name: name,
                                                                   team: ZMUser.selfUser().team)
         } completionHandler: { [weak self] in
             guard let self = self, let conversation = conversation else { return }
             self.state = .creatingConversation(conversation: conversation, eventHandler: eventHandler)
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
        eventHandler?(.hideLoader)
        eventHandler?(.success(conversation: conversation))
    }

    @objc func unsupportedErrorsHandler(notification: Notification) {
        guard extractConversation(notification: notification) != nil
            else { return }
        eventHandler?(.hideLoader)
        eventHandler?(.failure(failureType: .other))
    }

    @objc func missingLegalConsentErrorHandler(notification: Notification) {
        guard extractConversation(notification: notification) != nil
            else { return }
        typealias ConversationError = L10n.Localizable.Error.Conversation
        eventHandler?(.hideLoader)
        eventHandler?(
            .presentPopup(
                popupType: .missingLegalHoldConsent(
                    completionHandler: { [weak self] in
                        self?.eventHandler?(.failure(failureType: .missingLegalHoldConsent))
                    }
                )
            )
        )
    }

    @objc func nonFederatingBackendsErrorHandler(notification: Notification) {
            guard extractConversation(notification: notification) != nil
                else { return }
        guard let userInfo = notification.userInfo,
              userInfo.keys.contains(ZMConversation.UserInfoKeys.nonFederatingBackends.rawValue),
              let nonFederatingBackends = userInfo[ZMConversation.UserInfoKeys.nonFederatingBackends.rawValue] as? NonFederatingBackendsTuple
            else { return }
        eventHandler?(.hideLoader)
        eventHandler?(
            .presentPopup(
                popupType: .nonFederatingBackends(
                    backends: nonFederatingBackends,
                    actionHandler: { [weak self] action in
                        switch action {
                        case .editParticipantsList:
                            self?.finalize()
                        case .discardGroupCreation:
                            self?.eventHandler?(.failure(failureType: .nonFederatingBackends))
                            self?.finalize()
                        case .learnMore:
                            guard let url = URL(string: "https://support.wire.com") else { return }
                            self?.eventHandler?(.openURL(url: url))
                            self?.finalize()
                        }
                    }
                )
            )
        )
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
