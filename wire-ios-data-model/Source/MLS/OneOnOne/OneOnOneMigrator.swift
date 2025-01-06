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

import Foundation

// sourcery: AutoMockable
public protocol OneOnOneMigratorInterface {

    @discardableResult
    func migrateToMLS(
        userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> MLSGroupID

}

public struct OneOnOneMigrator: OneOnOneMigratorInterface {

    // MARK: - Dependencies

    private let mlsService: MLSServiceInterface

    // MARK: - Life cycle

    public init(mlsService: MLSServiceInterface) {
        self.mlsService = mlsService
    }

    // MARK: - Methods

    @discardableResult
    public func migrateToMLS(
        userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> MLSGroupID {
        // Fetch MLS 1:1 conversation and store it locally.
        let (mlsGroupID, removalKeys) = try await syncMLSConversationFromBackend(
            userID: userID,
            in: context
        )

        // Create or join the MLS conversation if needed.
        if try await !mlsService.conversationExists(groupID: mlsGroupID) {
            try await createOrJoinMLSConversationIfNeeded(
                userID: userID,
                mlsGroupID: mlsGroupID,
                removalKeys: removalKeys,
                in: context
            )
        }

        // Perform the migration of messages and link the MLS conversation if needed.
        // It's safe to attempt this step each time to enhance the resilience of the app.
        // This ensures that in cases where an MLS conversation exists but Proteus hasn't yet switched and the messages
        // haven't been migrated,
        // it will attempt the migration again.
        try await migrateMessagesAndLinkMLSConversationIfNeeded(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: context
        )

        await context.perform {
            _ = context.saveOrRollback()
        }

        return mlsGroupID
    }

    // MARK: Helpers

    private func syncMLSConversationFromBackend(
        userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> (MLSGroupID, BackendMLSPublicKeys?) {
        var action = SyncMLSOneToOneConversationAction(
            userID: userID.uuid,
            domain: userID.domain
        )

        do {
            return try await action.perform(in: context.notificationContext)
        } catch {
            throw MigrateMLSOneOnOneConversationError.failedToFetchConversation(error)
        }
    }

    private func fetchMLSConversationEpoch(
        mlsGroupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) async -> UInt64? {
        await context.perform {
            let conversation = ZMConversation.fetch(with: mlsGroupID, in: context)
            return conversation?.epoch
        }
    }

    private func establishMLSGroupIfNeeded(
        userID: QualifiedID,
        mlsGroupID: MLSGroupID,
        removalKeys: BackendMLSPublicKeys? = nil,
        in context: NSManagedObjectContext
    ) async throws {
        let users = [MLSUser(userID)]

        do {
            let ciphersuite = try await mlsService.establishGroup(
                for: mlsGroupID,
                with: users,
                removalKeys: removalKeys
            )
            await context.perform {
                let conversation = ZMConversation.fetch(with: mlsGroupID, in: context)
                conversation?.ciphersuite = ciphersuite
                conversation?.mlsStatus = .ready
            }
        } catch {
            throw MigrateMLSOneOnOneConversationError.failedToEstablishGroup(error)
        }
    }

    private func migrateMessagesAndLinkMLSConversationIfNeeded(
        userID: QualifiedID,
        mlsGroupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) async throws {
        try await context.perform {
            guard let mlsConversation = ZMConversation.fetch(
                with: mlsGroupID,
                in: context
            ) else {
                throw MigrateMLSOneOnOneConversationError.failedToActivateConversation
            }

            guard let otherUser = ZMUser.fetch(with: userID, in: context) else {
                throw MigrateMLSOneOnOneConversationError.failedToActivateConversation
            }


            // Note on proteus, it's possible to have 2 duplicate 1-1 conversations, so we need to fetch both conversations here.
            let proteusConversations: [ZMConversation] = fetchAllOneOnOneProteusConversations(otherUserID: userID, in: context)
            var allProteusConversations = Set(proteusConversations)
            if let oneOnOneConservsation = otherUser.oneOnOneConversation {
                allProteusConversations.insert(oneOnOneConservsation)
            }
            
            // move local messages from proteus conversation if it exists
            for proteusConversation in allProteusConversations {
                // Since ZMMessages only have a single conversation connected,
                // forming this union also removes the relationship to the proteus conversation.
                mlsConversation.mutableMessages.union(proteusConversation.allMessages)

            }
            if proteusConversations.count > 0 {
                // update just to be sure
                mlsConversation.needsToBeUpdatedFromBackend = true
            }

            // switch active conversation
            otherUser.oneOnOneConversation = mlsConversation
        }
    }
    
    func fetchAllOneOnOneProteusConversations(otherUserID: QualifiedID, in context: NSManagedObjectContext) -> [ZMConversation] {
        guard let otherUser = ZMUser.fetch(with: otherUserID.uuid, domain: otherUserID.domain, in: context) else {
            return []
        }
        let selfUser = ZMUser.selfUser(in: context)
        guard let selfTeam = selfUser.team else {
            return []
        }
        
        let request = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        request.predicate = ZMConversation.predicateForTeamOneToOneConversation()

        // We consider a conversation being an existing 1:1 team conversation in case the following points are true:
        //  1. It is a conversation inside the team
        //  2. The only participants are the current user and the selected user
        //  3. It does not have a custom display name
        let sameTeam = NSPredicate(format: "team == %@", selfTeam)
        let groupConversation = NSPredicate(
            format: "%K == %d",
            ZMConversationConversationTypeKey,
            ZMConversationType.group.rawValue
        )
        let noUserDefinedName = NSPredicate(format: "%K == NULL", ZMConversationUserDefinedNameKey)
        let sameParticipant = NSPredicate(
            format: "%K.@count == 2 AND ANY %K.user == %@ AND ANY %K.user == %@",
            ZMConversationParticipantRolesKey,
            ZMConversationParticipantRolesKey,
            otherUser,
            ZMConversationParticipantRolesKey,
            selfUser
        )

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            sameTeam,
            groupConversation,
            noUserDefinedName,
            sameParticipant
        ])

        
        return context.fetchOrAssert(request: request)
    }
}
