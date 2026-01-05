//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireNetwork
import WireFoundation

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
        guard conversation.canManageGuestsAccess else {
            throw SetAllowGuestsAndAppsUseCaseError.invalidOperation
        }

        guard let context = conversation.managedObjectContext else {
            throw SetAllowGuestsAndAppsUseCaseError.contextUnavailable
        }

        let conversationID = await context.perform {
            WireFoundation.QualifiedID(conversation.qualifiedID!)
        }

        try await api.updateConversationAccess(
            conversationID: conversationID,
            allowGuests: allowGuests,
            allowApps: allowApps
        )

//        return () // TODO: clean up? or fallback?
//
//        var action = SetAllowGuestsAndAppsAction(
//            allowGuests: allowGuests,
//            allowApps: allowApps,
//            conversationID: conversation.objectID
//        )
//
//        action.perform(in: context.notificationContext) { result in
//            switch result {
//            case .success:
//                completion(.success(()))
//            case let .failure(error):
//                completion(.failure(.networkError(error)))
//            }
//
//        }
    }
}

extension SetAllowGuestAndAppsUseCaseProtocol { // TODO: delete

    public func invoke(
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
