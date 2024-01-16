//
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

// sourcery: AutoMockable
public protocol OneOnOneResolverInterface {

    func resolveOneOnOneConversation(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws

}

public final class OneOnOneResolver: OneOnOneResolverInterface {

    // MARK: - Dependencies

    private let protocolSelector: OneOnOneProtocolSelectorInterface
    private let migrator: OneOnOneMigratorInterface

    // MARK: - Life cycle

    public convenience init?(syncContext: NSManagedObjectContext) {
        let mlsService = syncContext.performAndWait {
            syncContext.mlsService
        }

        guard let mlsService else {
            return nil
        }

        self.init(
            protocolSelector: OneOnOneProtocolSelector(),
            migrator: OneOnOneMigrator(mlsService: mlsService)
        )
    }

    public init(
        protocolSelector: OneOnOneProtocolSelectorInterface,
        migrator: OneOnOneMigratorInterface
    ) {
        self.protocolSelector = protocolSelector
        self.migrator = migrator
    }

    // MARK: - Methods

    public func resolveOneOnOneConversation(
        with userID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws {

        switch protocolSelector.getProtocolForUser(
            with: userID,
            in: context
        ) {

        case .none:
            await context.perform {
                guard
                    let otherUser = ZMUser.fetch(with: userID, in: context),
                    let conversation = otherUser.connection?.conversation
                else {
                    return
                }

                conversation.isForcedReadOnly = true
            }

        case .some(.mls):
            try await migrator.migrateToMLS(
                userID: userID,
                in: context
            )

        case .some(.proteus):
            break

        // This should never happen:
        // Users can only support proteus and mls protocols.
        // Mixed protocol is used by conversations to represent
        // the migration state when migrating from proteus to mls.
        case .some(.mixed):
            break
        }
    }

}
