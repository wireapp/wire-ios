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

// sourcery: AutoMockable
public protocol SetAllowGuestAndServicesUseCaseProtocol {

    func invoke(
        conversation: ZMConversation,
        allowGuests: Bool,
        allowServices: Bool,
        completion: @escaping (Result<Void, SetAllowGuestsAndServicesAction.Failure>) -> Void
    )
}

struct SetAllowGuestAndServicesUseCase: SetAllowGuestAndServicesUseCaseProtocol {

    func invoke(
        conversation: ZMConversation,
        allowGuests: Bool,
        allowServices: Bool,
        completion: @escaping (Result<Void, SetAllowGuestsAndServicesAction.Failure>) -> Void
    ) {
        guard conversation.canManageAccess else {
            return completion(.failure(.invalidOperation))
        }

        guard let apiVersion = BackendInfo.apiVersion else {
            return completion(.failure(.unknown))
        }

        guard let context = conversation.managedObjectContext else {
            return completion(.failure(.contextUnavailable))
        }

        var action = SetAllowGuestsAndServicesAction(
            allowGuests: allowGuests,
            allowServices: allowServices,
            conversationID: conversation.objectID
        )

        action.perform(in: context.notificationContext, resultHandler: completion)
        }
    }
