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

protocol GroupConversationCreator {
    func insertGroupConversation(
        moc: NSManagedObjectContext,
        participants: [ZMUser],
        name: String?,
        team: Team?,
        allowGuests: Bool,
        allowServices: Bool,
        readReceipts: Bool,
        messageProtocol: MessageProtocol
    ) -> ZMConversation?
}

class DefaultGroupConversationCreator: GroupConversationCreator {
    func insertGroupConversation(
        moc: NSManagedObjectContext,
        participants: [ZMUser],
        name: String?,
        team: Team?,
        allowGuests: Bool,
        allowServices: Bool,
        readReceipts: Bool,
        messageProtocol: MessageProtocol
    ) -> ZMConversation? {
            return ZMConversation.insertGroupConversation(
                moc: moc,
                participants: participants,
                name: name,
                team: team,
                allowGuests: allowGuests,
                allowServices: allowServices,
                readReceipts: readReceipts,
                messageProtocol: messageProtocol
            )
        }
}

class GroupConversationCreationCoordinator {
    enum GroupConversationCreationCoordinatorError: Error {
        case initializationFailure
        case creationFailure
    }
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

    private var creator: GroupConversationCreator

    init(creator: GroupConversationCreator = DefaultGroupConversationCreator()) {
        self.creator = creator
    }

    func initialize(eventHandler: @escaping (GroupConversationCreationEvent) -> Void) throws {
        guard case .ready = state else { throw GroupConversationCreationCoordinatorError.initializationFailure }
        state = .initializing
        NotificationCenter.default.addObserver(self, selector: #selector(missingLegalConsentErrorHandler), name: ZMConversation.missingLegalHoldConsentNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nonFederatingBackendsErrorHandler), name: ZMConversation.nonFederatingBackendsNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unsupportedErrorsHandler), name: ZMConversation.unknownResponseErrorNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(conversationCreatedHandler), name: ZMConversation.insertedConversationUpdatedNotificationName, object: nil)
        state = .initialized(eventHandler: eventHandler)
    }

    func createConversation(
        withUsers users: UserSet?,
        name: String?,
        allowGuests: Bool,
        allowServices: Bool,
        enableReceipts: Bool,
        encryptionProtocol: EncryptionProtocol,
        userSession: UserSessionInterface,
        moc: NSManagedObjectContext
     ) throws {
         guard case .initialized(let eventHandler) = state,
               let users = users
         else {
             throw GroupConversationCreationCoordinatorError.creationFailure
         }
         state = .beginingToCreateConversation(eventHandler: eventHandler)
         eventHandler(.showLoader)

         var conversation: ZMConversation?

         userSession.enqueue { [weak self] in
             conversation = self?.creator.insertGroupConversation(
                 moc: moc,
                 participants: users.materialize(in: moc),
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
        guard extractConversation(notification: notification) != nil,
            let userInfo = notification.userInfo,
            userInfo.keys.contains(ZMConversation.UserInfoKeys.nonFederatingBackends.rawValue),
            let nonFederatingBackends = userInfo[ZMConversation.UserInfoKeys.nonFederatingBackends.rawValue] as? NonFederatingBackends
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
                            self?.eventHandler?(.openURL(url: WireUrl.shared.support))
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
