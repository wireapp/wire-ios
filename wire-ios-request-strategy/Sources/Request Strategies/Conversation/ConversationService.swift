// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

public protocol ConversationServiceInterface {

    func createGroupConversation(
        name: String?,
        users: Set<ZMUser>,
        allowGuests: Bool,
        allowServices: Bool,
        enableReceipts: Bool,
        messageProtocol: MessageProtocol,
        completion: @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void
    )

    func syncConversation(
        qualifiedID: QualifiedID,
        completion: @escaping () -> Void
    )

}

public enum ConversationCreationFailure: Error {

    case missingPermissions
    case missingSelfClientID
    case conversationNotFound
    case networkError(CreateGroupConversationAction.Failure)

}


public final class ConversationService: ConversationServiceInterface {

    // MARK: - Properties

    let context: NSManagedObjectContext

    // MARK: - Life cycle

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Create conversation

    public func createGroupConversation(
        name: String?,
        users: Set<ZMUser>,
        allowGuests: Bool,
        allowServices: Bool,
        enableReceipts: Bool,
        messageProtocol: MessageProtocol,
        completion: @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void
    ) {
        if let teamID = ZMUser.selfUser(in: context).teamIdentifier {
            internalCreateTeamGroupConversation(
                teamID: teamID,
                name: name,
                users: users,
                allowGuests: allowGuests,
                allowServices: allowServices,
                enableReceipts: enableReceipts,
                messageProtocol: messageProtocol,
                completion: completion
            )
        } else {
            internalCreateGroupConversation(
                name: name,
                users: users,
                completion: completion
            )
        }
    }

    private func internalCreateTeamGroupConversation(
        teamID: UUID,
        name: String?,
        users: Set<ZMUser>,
        allowGuests: Bool,
        allowServices: Bool,
        enableReceipts: Bool,
        messageProtocol: WireDataModel.MessageProtocol,
        completion: @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void
    ) {
        guard ZMUser.selfUser(in: context).canCreateConversation(type: .group) else {
            completion(.failure(.missingPermissions))
            return
        }
        
        internalCreateGroupConversation(
            teamID: teamID,
            name: name,
            users: users,
            accessMode: ConversationAccessMode.value(forAllowGuests: allowGuests),
            accessRoles: ConversationAccessRoleV2.from(
                allowGuests: allowGuests,
                allowServices: allowServices
            ),
            enableReceipts: enableReceipts,
            messageProtocol: messageProtocol,
            completion: completion
        )
    }

    private func internalCreateGroupConversation(
        name: String?,
        users: Set<ZMUser>,
        completion: @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void
    ) {
        internalCreateGroupConversation(
            teamID: nil,
            name: name,
            users: users,
            accessMode: ConversationAccessMode(),
            accessRoles: [],
            enableReceipts: false,
            messageProtocol: .proteus,
            completion: completion
        )
    }

    private func internalCreateGroupConversation(
        teamID: UUID?,
        name: String?,
        users: Set<ZMUser>,
        accessMode: ConversationAccessMode,
        accessRoles: Set<ConversationAccessRoleV2>,
        enableReceipts: Bool,
        messageProtocol: WireDataModel.MessageProtocol,
        completion: @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void
    ) {
        let selfUser = ZMUser.selfUser(in: context)

        guard let selfClientID = selfUser.selfClient()?.remoteIdentifier else {
            completion(.failure(.missingSelfClientID))
            return
        }

        let usersExcludingSelfUser = users.filter { !$0.isSelfUser }
        let qualifiedUserIDs: [QualifiedID]
        let unqualifiedUserIDs: [UUID]

        if let ids = usersExcludingSelfUser.qualifiedUserIDs {
            qualifiedUserIDs = ids
            unqualifiedUserIDs = []
        } else {
            qualifiedUserIDs = []
            unqualifiedUserIDs = usersExcludingSelfUser.compactMap(\.remoteIdentifier)
        }

        var action = CreateGroupConversationAction(
            messageProtocol: messageProtocol,
            creatorClientID: selfClientID,
            qualifiedUserIDs: qualifiedUserIDs,
            unqualifiedUserIDs: unqualifiedUserIDs,
            name: name,
            accessMode: accessMode,
            accessRoles: accessRoles,
            legacyAccessRole: nil,
            teamID: teamID,
            isReadReceiptsEnabled: enableReceipts
        )

        action.perform(in: context.notificationContext) { result in
            self.context.perform {
                switch result {
                case .success(let objectID):
                    if let conversation = try? self.context.existingObject(with: objectID) as? ZMConversation {
                        completion(.success(conversation))
                    } else {
                        completion(.failure(.conversationNotFound))
                    }

                case .failure(let failure):
                    completion(.failure(.networkError(failure)))
                }
            }
        }
    }

    // MARK: - Sync conversation

    public func syncConversation(
        qualifiedID: QualifiedID,
        completion: @escaping () -> Void
    ) {
        var action = SyncConversationAction(qualifiedID: qualifiedID)
        action.perform(in: context.notificationContext) { _ in
            completion()
        }
    }

}
