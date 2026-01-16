//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

public enum CreateConversationGuestLinkUseCaseError: Error {

    case invalidOperation
    case contextUnavailable
    case networkError(Error)
    case failedToEnableGuestAccess(Error)

}

// sourcery: AutoMockable
public protocol CreateConversationGuestLinkUseCaseProtocol {

    func invoke(
        conversation: ZMConversation,
        password: String?,
        completion: @escaping (Result<String?, CreateConversationGuestLinkUseCaseError>) -> Void
    )

}

struct CreateConversationGuestLinkUseCase: CreateConversationGuestLinkUseCaseProtocol {

    let setGuestsAndAppsUseCase: SetAllowGuestAndAppsUseCaseProtocol

    public func invoke(
        conversation: ZMConversation,
        password: String?,
        completion: @escaping (Result<String?, CreateConversationGuestLinkUseCaseError>) -> Void
    ) {
        guard let context = conversation.managedObjectContext else {
            return completion(.failure(.contextUnavailable))
        }

        let completion = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }

        let isLegacyAccessMode = context.performAndWait { conversation.isLegacyAccessMode }
        if isLegacyAccessMode {
            Task {
                do {
                    let allowApps = await context.perform { conversation.allowApps }
                    try await setGuestsAndAppsUseCase.invoke(
                        conversation: conversation,
                        allowGuests: true,
                        allowApps: allowApps
                    )
                    await context.perform { [self] in
                        createGuestLink(conversation: conversation, password: password, completion)
                    }
                } catch {
                    completion(.failure(.failedToEnableGuestAccess(error)))
                }
            }
        } else {
            context.perform { [self] in
                createGuestLink(conversation: conversation, password: password, completion)
            }
        }
    }

    private func createGuestLink(
        conversation: ZMConversation,
        password: String?,
        _ completion: @escaping (Result<String?, CreateConversationGuestLinkUseCaseError>) -> Void
    ) {
        guard conversation.canManageGuestsAccess else {
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
