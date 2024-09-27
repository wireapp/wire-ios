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

// MARK: - CreateConversationGuestLinkUseCaseError

public enum CreateConversationGuestLinkUseCaseError: Error {
    case invalidOperation
    case contextUnavailable
    case networkError(Error)
    case failedToEnableGuestAccess(Error)
}

// MARK: - CreateConversationGuestLinkUseCaseProtocol

// sourcery: AutoMockable
public protocol CreateConversationGuestLinkUseCaseProtocol {
    func invoke(
        conversation: ZMConversation,
        password: String?,
        completion: @escaping (Result<String?, CreateConversationGuestLinkUseCaseError>) -> Void
    )
}

// MARK: - CreateConversationGuestLinkUseCase

struct CreateConversationGuestLinkUseCase: CreateConversationGuestLinkUseCaseProtocol {
    let setGuestsAndServicesUseCase: SetAllowGuestAndServicesUseCaseProtocol

    public func invoke(
        conversation: ZMConversation,
        password: String?,
        completion: @escaping (Result<String?, CreateConversationGuestLinkUseCaseError>) -> Void
    ) {
        if conversation.isLegacyAccessMode {
            setGuestsAndServicesUseCase.invoke(
                conversation: conversation,
                allowGuests: true,
                allowServices: conversation.allowServices
            ) { result in
                switch result {
                case let .failure(error):
                    completion(.failure(.failedToEnableGuestAccess(error)))
                case .success:
                    createGuestLink(conversation: conversation, password: password, completion)
                }
            }
        } else {
            createGuestLink(conversation: conversation, password: password, completion)
        }
    }

    private func createGuestLink(
        conversation: ZMConversation,
        password: String?,
        _ completion: @escaping (Result<String?, CreateConversationGuestLinkUseCaseError>) -> Void
    ) {
        guard conversation.canManageAccess else {
            completion(.failure(CreateConversationGuestLinkUseCaseError.invalidOperation))
            return
        }

        guard let context = conversation.managedObjectContext else {
            completion(.failure(CreateConversationGuestLinkUseCaseError.contextUnavailable))
            return
        }

        var action = CreateConversationGuestLinkAction(
            password: password,
            conversationID: conversation.remoteIdentifier
        )

        action.perform(in: context.notificationContext) { result in
            switch result {
            case let .success(link):
                completion(.success(link))
            case let .failure(error):
                completion(.failure(.networkError(error)))
            }
        }
    }
}
