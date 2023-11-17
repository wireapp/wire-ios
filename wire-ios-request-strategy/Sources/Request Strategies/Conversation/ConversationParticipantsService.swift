////
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

// sourcery: AutoMockable
protocol ConversationParticipantsServiceInterface {
    func addParticipants(
        _ users: [ZMUser],
        to conversation: ZMConversation,
        completion: @escaping AddParticipantAction.ResultHandler
    )

    func removeParticipant(
        _ user: ZMUser,
        from conversation: ZMConversation,
        completion: @escaping RemoveParticipantAction.ResultHandler
    )
}

class ConversationParticipantsService: ConversationParticipantsServiceInterface {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let proteusParticipantsService: ProteusConversationParticipantsServiceInterface
    private let mlsParticipantsService: MLSConversationParticipantsServiceInterface

    // MARK: - Life cycle

    convenience init(context: NSManagedObjectContext) {
        self.init(
            context: context,
            proteusParticipantsService: ProteusConversationParticipantsService(context: context),
            mlsParticipantsService: MLSConversationParticipantsService(context: context)
        )
    }

    init(
        context: NSManagedObjectContext,
        proteusParticipantsService: ProteusConversationParticipantsServiceInterface,
        mlsParticipantsService: MLSConversationParticipantsServiceInterface
    ) {
        self.context = context
        self.proteusParticipantsService = proteusParticipantsService
        self.mlsParticipantsService = mlsParticipantsService
    }

    // MARK: - Interface

    func addParticipants(
        _ users: [ZMUser],
        to conversation: ZMConversation,
        completion: @escaping AddParticipantAction.ResultHandler
    ) {
        guard
            conversation.conversationType == .group,
            !users.isEmpty,
            !users.contains(ZMUser.selfUser(in: context))
        else {
            completion(.failure(.invalidOperation))
            return
        }

        switch conversation.messageProtocol {
        case .proteus:
            proteusParticipantsService.addParticipants(
                users,
                to: conversation,
                completion: completion
            )
        case .mls:
            mlsParticipantsService.addParticipants(
                users,
                to: conversation,
                completion: completion
            )
        case .mixed:
            proteusParticipantsService.addParticipants(
                users,
                to: conversation,
                completion: completion
            )
            mlsParticipantsService.addParticipants(
                users,
                to: conversation,
                completion: { _ in }
            )
        }
    }

    func removeParticipant(
        _ user: ZMUser,
        from conversation: ZMConversation,
        completion: @escaping RemoveParticipantAction.ResultHandler
    ) {
        guard conversation.conversationType == .group else {
            return completion(.failure(ConversationRemoveParticipantError.invalidOperation))
        }

        switch (conversation.messageProtocol, user.isSelfUser) {

        case (.proteus, _), (.mixed, _), (.mls, true):
            proteusParticipantsService.removeParticipant(
                user,
                from: conversation,
                completion: completion
            )
        case (.mls, false):
            mlsParticipantsService.removeParticipant(
                user,
                from: conversation,
                completion: completion
            )
        }
    }
}
