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

import WireDataModel
import WireLogging
import WireNetwork

struct UserConnectionEventProcessor: UserConnectionEventProcessorProtocol {

    let context: NSManagedObjectContext
    let connectionsRepository: any ConnectionsRepositoryProtocol
    let oneOnOneResolver: any OneOnOneResolverProtocol

    private let oneOnOneResolutionDelay: TimeInterval = 3

    func processEvent(_ event: UserConnectionEvent) async throws {
        let connection = event.connection

        try await connectionsRepository.updateConnection(connection)

        guard let userID = event.connection.receiverQualifiedID?.toDomainModel() else { return }

        if connection.status == .accepted {
            // Using a Task to not block the sync for 3 seconds (`see oneOnOneResolutionDelay`)
            Task {
                do {
                    // The client who accepts the connection resolves the conversation immediately.
                    // Other clients (from self and other user) resolve after a delay to avoid a race condition,
                    // but also to re-attempt resolution in case of failure.
                    try await Task.sleep(for: .seconds(oneOnOneResolutionDelay))

                    try await oneOnOneResolver.resolveOneOnOneConversation(with: userID)

                    await context.perform {
                        _ = context.saveOrRollback()
                    }
                } catch {
                    WireLogger.conversation.error("Error resolving one-on-one conversation: \(error)")
                }
            }

        } else {
            let userObjectID = await context.perform { [context] in
                ZMUser.fetch(with: userID.uuid, domain: userID.domain, in: context)?.objectID
            }

            guard let userObjectID else {
                return WireLogger.individualToTeamMigration.error(
                    "User not found for connection event"
                )
            }

            do {
                let connectionValidator = ConnectionValidator(context: context)
                try await connectionValidator.cleanUpInvalidConnectionIfNeeded(userObjectID: userObjectID)
                try await oneOnOneResolver.resolveOneOnOneConversation(with: userID)
            } catch {
                WireLogger.individualToTeamMigration.error(
                    "failed to clean up invalid connection: \(String(describing: error))"
                )
            }

        }
    }
}
