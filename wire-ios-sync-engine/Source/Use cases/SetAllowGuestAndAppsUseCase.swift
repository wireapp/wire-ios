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
        allowApps: Bool,
        completion: @escaping (Result<Void, SetAllowGuestsAndAppsUseCaseError>) -> Void
    )
}

struct SetAllowGuestAndAppsUseCase: SetAllowGuestAndAppsUseCaseProtocol {

    func invoke(
        conversation: ZMConversation,
        allowGuests: Bool,
        allowApps: Bool,
        completion: @escaping (Result<Void, SetAllowGuestsAndAppsUseCaseError>) -> Void
    ) {
        guard conversation.canManageGuestsAccess else {
            return completion(.failure(.invalidOperation))
        }

        guard let context = conversation.managedObjectContext else {
            return completion(.failure(.contextUnavailable))
        }

        var action = SetAllowGuestsAndAppsAction(
            allowGuests: allowGuests,
            allowApps: allowApps,
            conversationID: conversation.objectID
        )

        action.perform(in: context.notificationContext) { result in
            switch result {
            case .success:
                completion(.success(()))
            case let .failure(error):
                completion(.failure(.networkError(error)))
            }

        }
    }
}
