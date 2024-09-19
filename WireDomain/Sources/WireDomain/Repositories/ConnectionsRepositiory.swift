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
import WireAPI
import WireDataModel

/// Facilitate access to connections related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
protocol ConnectionsRepositoryProtocol {

    /// Pull self team metadata frmo the server and store locally.

    func pullConnections() async throws

    /// Removes a federation connection between two domains.
    ///
    /// - Parameter domain: The domain for which the connection was removed.
    /// - Parameter otherDomain: The other domain for which the connection was removed.

    func removeFederationConnection(between domain: String, and otherDomain: String) async
}

struct ConnectionsRepository: ConnectionsRepositoryProtocol {

    // MARK: - Properties

    private let connectionsAPI: any ConnectionsAPI
    private let context: NSManagedObjectContext

    // MARK: - Object lifecycle

    init(
        connectionsAPI: any ConnectionsAPI,
        context: NSManagedObjectContext
    ) {
        self.connectionsAPI = connectionsAPI
        self.context = context
    }

    // MARK: - Public

    /// Retrieve from backend and store connections locally

    public func pullConnections() async throws {
        let connectionsPager = try await connectionsAPI.getConnections()

        for try await connections in connectionsPager {
            await withThrowingTaskGroup(of: Void.self) { taskGroup in
                for connection in connections {
                    taskGroup.addTask {
                        try await storeConnection(connection)
                    }
                }
            }
        }
    }

    public func removeFederationConnection(
        between domain: String,
        and otherDomain: String
    ) async {
        await context.perform { [self] in

            /// For all conversations that are NOT owned by `domain` or `otherDomain` and contain users from `domain` and `otherDomain`, remove users from `domain` and `otherDomain` from those conversations.

            removeFederationConnection(
                with: [domain, otherDomain],
                forConversationsNotOwnedBy: [domain, otherDomain]
            )

            /// For all conversations owned by `otherDomain` that contains users from `domain`, remove users from `domain` from those conversations.

            removeFederationConnection(
                with: domain,
                forConversationsOwnedBy: otherDomain
            )

            /// For all conversations owned by `domain` that contains users from `otherDomain`, remove users from `otherDomain` from those conversations.

            removeFederationConnection(
                with: otherDomain,
                forConversationsOwnedBy: domain
            )
        }
    }

    // MARK: - Private

    private func removeFederationConnection(
        with userDomains: Set<String>,
        forConversationsNotOwnedBy domains: Set<String>
    ) {
        let notHostedConversations = fetchNotHostedConversations(
            excludedDomains: domains,
            withParticipantsOn: userDomains
        )

        for notHostedConversation in notHostedConversations {
            let participants = getParticipants(from: notHostedConversation, on: userDomains)

            removeFederationConnection(
                for: notHostedConversation,
                with: participants,
                on: userDomains
            )
        }
    }

    private func removeFederationConnection(
        with userDomain: String,
        forConversationsOwnedBy domain: String
    ) {
        let hostedConversations = fetchHostedConversations(
            on: domain,
            withParticipantsOn: userDomain
        )

        for hostedConversation in hostedConversations {
            let participants = getParticipants(from: hostedConversation, on: [userDomain])

            removeFederationConnection(
                for: hostedConversation,
                with: participants,
                on: [userDomain, domain]
            )
        }
    }

    private func removeFederationConnection(
        for conversation: ZMConversation,
        with participants: Set<ZMUser>,
        on domains: Set<String>
    ) {
        let selfUser = ZMUser.selfUser(in: context)

        conversation.appendFederationTerminationSystemMessage(
            domains: Array(domains),
            sender: selfUser,
            at: .now
        )

        conversation.removeParticipantsLocally(participants)

        conversation.appendParticipantsRemovedAnonymouslySystemMessage(
            users: participants,
            sender: selfUser,
            removedReason: .federationTermination,
            at: .now
        )
    }

    private func fetchHostedConversations(
        on domain: String,
        withParticipantsOn userDomain: String
    ) -> [ZMConversation] {
        let groupConversation = ZMConversation.groupConversations(
            hostedOnDomain: domain,
            in: context
        )

        return groupConversation.filter {
            let localParticipants = Set($0.participantRoles.compactMap(\.user))
            let localParticipantDomains = Set(localParticipants.compactMap(\.domain))

            let userDomains = Set([userDomain])

            return userDomains.isSubset(of: localParticipantDomains)
        }
    }

    private func fetchNotHostedConversations(
        excludedDomains: Set<String>,
        withParticipantsOn userDomains: Set<String>
    ) -> [ZMConversation] {
        let groupConversation = ZMConversation.groupConversations(
            notHostedOnDomains: Array(excludedDomains),
            in: context
        )

        return groupConversation.filter {
            let localParticipants = Set($0.participantRoles.compactMap(\.user))
            let localParticipantDomains = Set(localParticipants.compactMap(\.domain))

            return userDomains.isSubset(of: localParticipantDomains)
        }
    }

    private func getParticipants(
        from conversation: ZMConversation,
        on domains: Set<String>
    ) -> Set<ZMUser> {
        let localParticipants = Set(conversation.participantRoles.compactMap(\.user))

        let participants = localParticipants.filter { user in
            if let domain = user.domain {
                domain.isOne(of: domains)
            } else {
                false
            }
        }

        return participants
    }

    /// Save connection and related objects to local storage.
    /// - Parameter connectionPayload: connection object from WireAPI

    private func storeConnection(_ connectionPayload: Connection) async throws {
        try await context.perform { [self] in

            let connection = try storedConnection(from: connectionPayload)

            let conversation = try storedConversation(from: connectionPayload, with: connection)

            connection.to.oneOnOneConversation = conversation

            try context.save()
        }
    }

    /// Create or update conversation related to the connection's sender
    /// - Parameters:
    ///   - connection: connection payload from WireAPI
    ///   - storedConnection: ZMConnection object stored locally
    /// - Returns: conversation object stored locally

    private func storedConversation(from connection: Connection, with storedConnection: ZMConnection) throws -> ZMConversation {
        guard let conversationID = connection.conversationID ?? connection.qualifiedConversationID?.uuid else {
            throw ConnectionsRepositoryError.missingConversationId
        }

        let conversation = ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: connection.qualifiedConversationID?.domain,
            in: context
        )

        conversation.needsToBeUpdatedFromBackend = true
        conversation.lastModifiedDate = connection.lastUpdate
        conversation.addParticipantAndUpdateConversationState(user: storedConnection.to, role: nil)
        return conversation
    }

    /// Create or update  connection locally related to the connection's sender
    /// - Parameter connection: connection payload from WireAPI
    /// - Returns: connection object stored locally

    private func storedConnection(from connection: Connection) throws -> ZMConnection {
        guard let userID = connection.receiverID ?? connection.receiverQualifiedID?.uuid else {
            throw ConnectionsRepositoryError.missingReceiverId
        }

        let storedConnection = ZMConnection.fetchOrCreate(
            userID: userID,
            domain: connection.receiverQualifiedID?.domain,
            in: context
        )

        storedConnection.status = status(from: connection.status)
        storedConnection.lastUpdateDateInGMT = connection.lastUpdate
        return storedConnection
    }

    /// Converts ConnectionStatus to stored connectionStatus
    /// - Parameter connectionStatus: WireAPI's ConnectionStatus
    /// - Returns: stored ConnectionStatus

    private func status(from connectionStatus: ConnectionStatus) -> ZMConnectionStatus {
        switch connectionStatus {
        case .sent:
            .sent
        case .accepted:
            .accepted
        case .pending:
            .pending
        case .blocked:
            .blocked
        case .cancelled:
            .cancelled
        case .ignored:
            .ignored
        case .missingLegalholdConsent:
            .blockedMissingLegalholdConsent
        }
    }
}
