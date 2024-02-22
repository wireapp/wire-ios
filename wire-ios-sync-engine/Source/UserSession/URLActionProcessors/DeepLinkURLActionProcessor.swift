//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

    var contextProvider: ContextProvider
    var transportSession: TransportSessionType
    var eventProcessor: UpdateEventProcessor

    init(contextProvider: ContextProvider,
         transportSession: TransportSessionType,
         eventProcessor: UpdateEventProcessor) {
        self.contextProvider = contextProvider
        self.transportSession = transportSession
        self.eventProcessor = eventProcessor
    }

    func process(urlAction: URLAction, delegate: PresentationDelegate?) {
        switch urlAction {
        case let .joinConversation(key: key, code: code):
            ZMConversation.fetchIdAndName(
                key: key,
                code: code,
                transportSession: transportSession,
                contextProvider: contextProvider
            ) { [weak self] (response) in

                guard let strongSelf = self,
                      let delegate = delegate else {
                    return
                }

                let viewContext = strongSelf.contextProvider.viewContext

                switch response {
                case .success((let conversationId, let conversationName)):
                    // First of all, we should try to fetch the conversation with ID from the response.
                    // If the conversation doesn't exist, we should initiate a request to join the conversation
                    if let conversation = ZMConversation.fetch(with: conversationId, in: viewContext),
                       conversation.isSelfAnActiveMember {
                        delegate.showConversation(conversation, at: nil)
                        delegate.completedURLAction(urlAction)
                    } else {
                        delegate.shouldPerformActionWithMessage(conversationName, action: urlAction) { shouldJoin in

                            guard shouldJoin else {
                                delegate.completedURLAction(urlAction)
                                return
                            }

                            ZMConversation.join(
                                key: key,
                                code: code,
                                transportSession: strongSelf.transportSession,
                                eventProcessor: strongSelf.eventProcessor,
                                contextProvider: strongSelf.contextProvider
                            ) { [weak self] (response) in

                                guard let strongSelf = self else { return }

                                switch response {
                                case .success(let conversation):
                                    strongSelf.synchronise(conversation) { result in
                                        DispatchQueue.main.async {
                                            switch result {
                                            case .success(let syncConversation):
                                                delegate.showConversation(syncConversation, at: nil)
                                            case .failure(let error):
                                                delegate.failedToPerformAction(urlAction, error: error)
                                            }
                                        }
                                    }
                                case .failure(let error):
                                    delegate.failedToPerformAction(urlAction, error: error)
                                }

                                delegate.completedURLAction(urlAction)
                            }
                        }
                    }

                case .failure(let error):
                    delegate.failedToPerformAction(urlAction, error: error)
                    delegate.completedURLAction(urlAction)
                }
            }

        case .openConversation(let id):
            let viewContext = contextProvider.viewContext
            guard let conversation = ZMConversation.fetch(with: id, domain: nil, in: viewContext) else {
                delegate?.failedToPerformAction(urlAction, error: DeepLinkRequestError.invalidConversationLink)
                return
            }

            delegate?.showConversation(conversation, at: nil)
            delegate?.completedURLAction(urlAction)

        case .openUserProfile(let id):
            let viewContext = contextProvider.viewContext
            if let user = ZMUser.fetch(with: id, domain: nil, in: viewContext) {
                delegate?.showUserProfile(user: user)
            } else {
                delegate?.showConnectionRequest(userId: id)
            }

            delegate?.completedURLAction(urlAction)

        default:
            delegate?.completedURLAction(urlAction)
        }
    }

    private func synchronise(_ conversation: ZMConversation, completion: @escaping (Result<ZMConversation, Error>) -> Void) {
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
                if let error = error {
                    WireLogger.mls.debug("failed to join MLS group: \(error)")
                    completion(.failure(error))
                } else {
                    completion(.success(upToDateConversation))
                }
            }
        }
    }
}
