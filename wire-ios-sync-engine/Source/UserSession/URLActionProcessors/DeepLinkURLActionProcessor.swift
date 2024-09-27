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
import WireRequestStrategy

class DeepLinkURLActionProcessor: URLActionProcessor {
    // MARK: Lifecycle

    init(
        contextProvider: ContextProvider,
        transportSession: TransportSessionType,
        eventProcessor: ConversationEventProcessorProtocol
    ) {
        self.contextProvider = contextProvider
        self.transportSession = transportSession
        self.eventProcessor = eventProcessor
    }

    // MARK: Internal

    var contextProvider: ContextProvider
    var transportSession: TransportSessionType
    var eventProcessor: ConversationEventProcessorProtocol

    func process(urlAction: URLAction, delegate: PresentationDelegate?) {
        switch urlAction {
        case let .joinConversation(key: key, code: code):
            handleJoinConversation(key: key, code: code, urlAction: urlAction, delegate: delegate)

        case let .openConversation(id):
            handleOpenConversation(id: id, delegate: delegate)

        case let .openUserProfile(id):
            handleOpenUserProfile(id: id, delegate: delegate)

        default:
            delegate?.completedURLAction(urlAction)
        }
    }

    // MARK: Private

    private func handleJoinConversation(
        key: String,
        code: String,
        urlAction: URLAction,
        delegate: PresentationDelegate?
    ) {
        ZMConversation.fetchIdAndName(
            key: key,
            code: code,
            transportSession: transportSession,
            contextProvider: contextProvider
        ) { [weak self] response in
            guard let self, let delegate else {
                return
            }

            let viewContext = contextProvider.viewContext

            switch response {
            case let .success((conversationId, conversationName, hasPassword)):
                if let conversation = ZMConversation.fetch(with: conversationId, in: viewContext),
                   conversation.isSelfAnActiveMember {
                    delegate.showConversation(conversation, at: nil)
                    delegate.completedURLAction(urlAction)
                } else if hasPassword {
                    handlePasswordPrompt(for: conversationName, key: key, code: code, delegate: delegate)
                } else {
                    handleJoinWithoutPassword(
                        for: conversationName,
                        key: key,
                        code: code,
                        urlAction: urlAction,
                        delegate: delegate
                    )
                }

            case let .failure(error):
                handleJoinConversationFailure(error: error, urlAction: urlAction, delegate: delegate)
            }
        }
    }

    private func handleJoinConversationFailure(
        error: Error,
        urlAction: URLAction,
        delegate: PresentationDelegate
    ) {
        delegate.failedToPerformAction(urlAction, error: error)
        delegate.completedURLAction(urlAction)
    }

    private func handlePasswordPrompt(
        for conversationName: String,
        key: String,
        code: String,
        delegate: PresentationDelegate
    ) {
        delegate.showPasswordPrompt(for: conversationName) { [weak self] password in
            guard let self, let password, !password.isEmpty else {
                return
            }

            joinConversation(key: key, code: code, password: password, delegate: delegate)
        }
    }

    private func handleJoinWithoutPassword(
        for conversationName: String,
        key: String,
        code: String,
        urlAction: URLAction,
        delegate: PresentationDelegate
    ) {
        delegate.shouldPerformActionWithMessage(conversationName, action: .joinConversation(
            key: key,
            code: code
        )) { [weak self] shouldJoin in
            guard let self, shouldJoin else {
                delegate.completedURLAction(urlAction)
                return
            }

            joinConversation(key: key, code: code, password: nil, delegate: delegate)
        }
    }

    private func joinConversation(
        key: String,
        code: String,
        password: String?,
        delegate: PresentationDelegate
    ) {
        ZMConversation.join(
            key: key,
            code: code,
            password: password,
            transportSession: transportSession,
            eventProcessor: eventProcessor,
            contextProvider: contextProvider
        ) { [weak self] response in
            guard let self else { return }

            switch response {
            case let .success(conversation):
                handleConversationSynchronization(
                    conversation: conversation,
                    key: key,
                    code: code,
                    delegate: delegate
                )

            case let .failure(error):
                delegate.failedToPerformAction(.joinConversation(key: key, code: code), error: error)
            }

            delegate.completedURLAction(.joinConversation(key: key, code: code))
        }
    }

    private func handleConversationSynchronization(
        conversation: ZMConversation,
        key: String,
        code: String,
        delegate: PresentationDelegate
    ) {
        synchronise(conversation) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(syncConversation):
                    delegate.showConversation(syncConversation, at: nil)
                case let .failure(error):
                    delegate.failedToPerformAction(.joinConversation(key: key, code: code), error: error)
                }
            }
        }
    }

    private func handleOpenConversation(id: UUID, delegate: PresentationDelegate?) {
        let viewContext = contextProvider.viewContext

        guard let conversation = ZMConversation.fetch(with: id, domain: nil, in: viewContext) else {
            delegate?.failedToPerformAction(
                .openConversation(id: id),
                error: DeepLinkRequestError.invalidConversationLink
            )
            return
        }

        delegate?.showConversation(conversation, at: nil)
        delegate?.completedURLAction(.openConversation(id: id))
    }

    private func handleOpenUserProfile(id: UUID, delegate: PresentationDelegate?) {
        let viewContext = contextProvider.viewContext

        if let user = ZMUser.fetch(with: id, domain: nil, in: viewContext) {
            delegate?.showUserProfile(user: user)
        } else {
            delegate?.showConnectionRequest(userId: id)
        }

        delegate?.completedURLAction(.openUserProfile(id: id))
    }

    private func synchronise(
        _ conversation: ZMConversation,
        completion: @escaping (Result<ZMConversation, Error>) -> Void
    ) {
        guard let qualifiedID = conversation.qualifiedID else {
            completion(.success(conversation))
            return
        }

        let service = ConversationService(context: contextProvider.syncContext)
        let viewContext = contextProvider.viewContext

        service.syncConversation(qualifiedID: qualifiedID) {
            guard let upToDateConversation = ZMConversation.fetch(with: qualifiedID, in: viewContext) else {
                // proceed showing the group anyway
                completion(.success(conversation))
                return
            }

            guard
                let groupId = upToDateConversation.mlsGroupID,
                upToDateConversation.messageProtocol.isOne(of: .mls, .mixed)
            else {
                completion(.success(upToDateConversation))
                return
            }

            upToDateConversation.joinNewMLSGroup(id: groupId) { error in
                if let error {
                    WireLogger.mls.debug("failed to join MLS group: \(error)")
                    completion(.failure(error))
                } else {
                    completion(.success(upToDateConversation))
                }
            }
        }
    }
}
