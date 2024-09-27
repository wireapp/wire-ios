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

/// Consumes self user client update events
///
/// Self user clients are clients belonging to the self user.

@objcMembers
public class UserClientEventConsumer: NSObject, ZMEventAsyncConsumer {
    // MARK: Lifecycle

    public init(
        managedObjectContext: NSManagedObjectContext,
        clientRegistrationStatus: ZMClientRegistrationStatus,
        clientUpdateStatus: ClientUpdateStatus,
        resolveOneOnOneConversations: any ResolveOneOnOneConversationsUseCaseProtocol
    ) {
        self.managedObjectContext = managedObjectContext
        self.clientRegistrationStatus = clientRegistrationStatus
        self.clientUpdateStatus = clientUpdateStatus
        self.resolveOneOnOneConversations = resolveOneOnOneConversations

        super.init()
    }

    // MARK: Public

    public func processEvents(_ events: [ZMUpdateEvent]) async {
        for event in events {
            do {
                try await processUpdateEvent(event)
            } catch {
                WireLogger.updateEvent.error(
                    "failed to process user client event: \(event.safeForLoggingDescription): \(error)",
                    attributes: .safePublic
                )
            }
        }
    }

    // MARK: Private

    private let managedObjectContext: NSManagedObjectContext
    private let clientRegistrationStatus: ZMClientRegistrationStatus
    private let clientUpdateStatus: ClientUpdateStatus
    private let resolveOneOnOneConversations: ResolveOneOnOneConversationsUseCaseProtocol

    private func processUpdateEvent(_ event: ZMUpdateEvent) async throws {
        switch event.type {
        case .userClientAdd, .userClientRemove:
            try await processClientListUpdateEvent(event)
        default:
            break
        }
    }

    private func processClientListUpdateEvent(_ event: ZMUpdateEvent) async throws {
        guard let clientInfo = event.payload["client"] as? [String: AnyObject] else {
            WireLogger.updateEvent.error("Client info has unexpected payload", attributes: .safePublic)
            return
        }

        switch event.type {
        case .userClientAdd:
            await managedObjectContext.perform {
                if let client = UserClient
                    .createOrUpdateSelfUserClient(clientInfo, context: self.managedObjectContext) {
                    let clientSet: Set<UserClient> = [client]
                    let selfUser = ZMUser.selfUser(in: self.managedObjectContext)
                    selfUser.selfClient()?.addNewClientToIgnored(client)
                    selfUser.selfClient()?.updateSecurityLevelAfterDiscovering(clientSet)
                }
            }

        case .userClientRemove:
            guard let clientID = clientInfo["id"] as? String else {
                return
            }

            let (clientToDelete, isSelfClient) = await managedObjectContext.perform {
                let selfUser = ZMUser.selfUser(in: self.managedObjectContext)
                let client = selfUser.clients.first { $0.remoteIdentifier == clientID }
                return (client, client?.isSelfClient())
            }

            if isSelfClient == true {
                await managedObjectContext.perform {
                    self.clientRegistrationStatus.didDetectCurrentClientDeletion()
                    self.clientUpdateStatus.didDetectCurrentClientDeletion()
                }
            } else {
                await clientToDelete?.deleteClientAndEndSession()
                try await resolveOneOnOneConversations.invoke()
            }

        default:
            break
        }
    }
}
