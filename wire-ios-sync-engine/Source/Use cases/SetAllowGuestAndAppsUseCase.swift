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

import WireFoundation
import WireNetwork

public enum SetAllowGuestsAndAppsUseCaseError: Error {

    case invalidOperation
    case contextUnavailable
    case networkError(Error)

}

// sourcery: AutoMockable
public protocol SetAllowGuestAndAppsUseCaseProtocol {

    func invoke(
        conversation: ZMConversation,
        allowGuests: Bool,
        allowApps: Bool
    ) async throws

    func invoke(
        conversation: ZMConversation,
        allowGuests: Bool,
        allowApps: Bool,
        completion: @escaping (Result<Void, SetAllowGuestsAndAppsUseCaseError>) -> Void
    )

}

struct SetAllowGuestAndAppsUseCase: SetAllowGuestAndAppsUseCaseProtocol {

    let api: any ConversationsAPI

    func invoke(
        conversation: ZMConversation,
        allowGuests: Bool,
        allowApps: Bool
    ) async throws {

        guard let context = conversation.managedObjectContext else {
            throw SetAllowGuestsAndAppsUseCaseError.contextUnavailable
        }

        let (canManageGuestsAccess, conversationID) = await context.perform {
            let canManageGuestsAccess = conversation.canManageGuestsAccess
            let conversationID = WireFoundation.QualifiedID(conversation.qualifiedID!)
            return (canManageGuestsAccess, conversationID)
        }

        guard canManageGuestsAccess else {
            throw SetAllowGuestsAndAppsUseCaseError.invalidOperation
        }

        try await api.updateConversationAccess(
            conversationID: conversationID,
            allowGuests: allowGuests,
            allowApps: allowApps
        )

        await context.perform {
            conversation.allowApps = allowApps
            conversation.allowGuests = allowGuests
        }
    }
}

public extension SetAllowGuestAndAppsUseCaseProtocol { // TODO: delete

    func invoke(
        conversation: ZMConversation,
        allowGuests: Bool,
        allowApps: Bool,
        completion: @escaping (Result<Void, SetAllowGuestsAndAppsUseCaseError>) -> Void
    ) {
        Task {
            do {
                try await invoke(
                    conversation: conversation,
                    allowGuests: allowGuests,
                    allowApps: allowApps
                )
                completion(.success(()))
            } catch let error as SetAllowGuestsAndAppsUseCaseError {
                completion(.failure(error))
            } catch {
                completion(.failure(.networkError(error)))
            }
        }
    }

}
