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

// MARK: - CreateTeamOneOnOneConversationUseCaseProtocol

protocol CreateTeamOneOnOneConversationUseCaseProtocol {
    func invoke(
        with user: ZMUser,
        syncContext: NSManagedObjectContext
    ) async throws -> NSManagedObjectID
}

// MARK: - CreateTeamOneOnOneConversationError

public enum CreateTeamOneOnOneConversationError: Error {
    case userDoesNotExist
    case userIsNotOnSameTeam
    case missingUserQualifiedID
    case mlsMigratorNotFound
    case failedToCreateMLSConversation(Error)
    case failedToCreateProteusConversation(Error)
    case noCommonProtocols
    case conversationNotFound
}

// MARK: - CreateTeamOneOnOneConversationUseCase

/// Creates the team one on one conversation with a particular user, depending
/// on the currently supported protocols of the self and other users.

struct CreateTeamOneOnOneConversationUseCase: CreateTeamOneOnOneConversationUseCaseProtocol {
    // MARK: Lifecycle

    init(
        protocolSelector: OneOnOneProtocolSelectorInterface = OneOnOneProtocolSelector(),
        migrator: OneOnOneMigratorInterface?,
        service: ConversationServiceInterface
    ) {
        self.protocolSelector = protocolSelector
        self.migrator = migrator
        self.service = service
    }

    // MARK: Internal

    func invoke(
        with user: ZMUser,
        syncContext: NSManagedObjectContext
    ) async throws -> NSManagedObjectID {
        let userID = try await syncContext.perform {
            guard user.isOnSameTeam(otherUser: ZMUser.selfUser(in: syncContext)) else {
                throw Error.userIsNotOnSameTeam
            }

            guard
                let userID = user.remoteIdentifier,
                let domain = user.domain ?? BackendInfo.domain
            else {
                throw Error.missingUserQualifiedID
            }

            return QualifiedID(
                uuid: userID,
                domain: domain
            )
        }

        switch try await protocolSelector.getProtocolForUser(
            with: userID,
            in: syncContext
        ) {
        case .mls:
            return try await createMLSConversation(
                userID: userID,
                in: syncContext
            )

        case .proteus:
            return try await createProteusConversation(
                with: user,
                in: syncContext
            )

        case .none, .mixed:
            throw Error.noCommonProtocols
        }
    }

    // MARK: Private

    private typealias Error = CreateTeamOneOnOneConversationError

    private let protocolSelector: OneOnOneProtocolSelectorInterface
    private let migrator: OneOnOneMigratorInterface?
    private let service: ConversationServiceInterface

    // MARK: MLS

    private func createMLSConversation(
        userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> NSManagedObjectID {
        guard let migrator else {
            throw Error.mlsMigratorNotFound
        }

        let groupID: MLSGroupID

        do {
            groupID = try await migrator.migrateToMLS(
                userID: userID,
                in: context
            )
        } catch {
            throw Error.failedToCreateMLSConversation(error)
        }

        return try await context.perform {
            guard let conversation = ZMConversation.fetch(with: groupID, in: context) else {
                throw Error.conversationNotFound
            }

            return conversation.objectID
        }
    }

    // MARK: Proteus

    private func createProteusConversation(
        with user: ZMUser,
        in context: NSManagedObjectContext
    ) async throws -> NSManagedObjectID {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                service.createTeamOneOnOneProteusConversation(user: user) {
                    switch $0 {
                    case let .success(conversation):
                        continuation.resume(returning: conversation.objectID)

                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
