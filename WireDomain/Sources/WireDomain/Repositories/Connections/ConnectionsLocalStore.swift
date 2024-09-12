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
import CoreData
import WireAPI
import WireDataModel

// sourcery: AutoMockable
protocol ConnectionsLocalStoreProtocol {
    
    func storeConnection(
        _ connectionPayload: Connection
    ) async throws
    
    func deleteFederationConnection(
        with domain: String
    ) async throws
    
    func removeFederationConnection(
        between domain: String,
        and otherDomain: String
    ) async
    
}

final class ConnectionsLocalStore: ConnectionsLocalStoreProtocol {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    
    // MARK: - Object lifecycle
    
    init(
        context: NSManagedObjectContext
    ) {
        self.context = context
    }
    
    // MARK: - Public
    
    /// Save connection and related objects to local storage.
    /// - Parameter connectionPayload: connection object from WireAPI

    public func storeConnection(_ connectionPayload: Connection) async throws {
        try await context.perform { [self] in

            let connection = try storedConnection(from: connectionPayload)

            let conversation = try storedConversation(from: connectionPayload, with: connection)

            connection.to.oneOnOneConversation = conversation

            try context.save()
        }
    }
    
    /// Deletes a federation connection on a specific domain locally.
    /// - Parameter domain: The domain to delete the connection for.

    public func deleteFederationConnection(with domain: String) async throws {
        await context.perform { [self] in
            let selfUserDomain = ZMUser.selfUser(in: context).domain ?? ""
            
            /// For all conversations owned by self domain, remove all users that belong to `domain` from those conversations.
            removeFederationConnection(
                with: domain,
                forConversationsOwnedBy: selfUserDomain
            )
            
            /// For all conversations owned by `domain`, remove all users from self domain from those conversations.
            removeFederationConnection(
                with: selfUserDomain,
                forConversationsOwnedBy: domain
            )
            
            /// For all conversations that are NOT owned by self domain or `domain` and contain users from self domain and `domain`, remove users from `domain` and `otherDomain` from those conversations.
            removeFederationConnection(
                with: [selfUserDomain, domain],
                forConversationsNotOwnedBy: [selfUserDomain, domain]
            )
            
            /// For any connection from a user on self domain to a user on `domain`, delete the connection.
            removeConnectionRequests(with: domain)
            
            /// For any 1:1 conversation, where one of the two users is on `domain`, remove self user from those conversations.
            markOneToOneConversationsAsReadOnly(with: domain)
            
            /// Remove connection for all connected users owned by `domain`.
            removeConnectedUsers(with: domain)
        }
    }
    
    /// Removes a federation connection between two specific domains locally.
    /// - Parameter domain: The first domain.
    /// - Parameter otherDomain: The other domain.

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
    
    private func removeConnectionRequests(with domain: String) {
        let sentAndPendingConnectionsPredicate = ZMUser.predicateForSentAndPendingConnections(hostedOnDomain: domain)
        
        let pendingUsersFetchRequest = ZMUser.sortedFetchRequest(with: sentAndPendingConnectionsPredicate)
        
        if let pendingUsers = context.fetchOrAssert(
            request: pendingUsersFetchRequest
        ) as? [ZMUser] {
            pendingUsers.forEach { user in
                let isPendingConnection = user.connection?.status == .pending
                user.connection?.status = isPendingConnection ? .ignored : .cancelled
            }
        }
    }
    
    private func markOneToOneConversationsAsReadOnly(with domain: String) {
        let connectedUsersPredicate = ZMUser.predicateForConnectedUsers(
            hostedOnDomain: domain
        )
        
        let fetchRequest = ZMUser.sortedFetchRequest(
            with: connectedUsersPredicate
        )
        
        let selfUser = ZMUser.selfUser(in: context)
        let selfUserDomain = selfUser.domain ?? ""
        
        if let users = context.fetchOrAssert(
            request: fetchRequest
        ) as? [ZMUser] {
            users
                .compactMap(\.oneOnOneConversation)
                .filter { !$0.isForcedReadOnly }
                .forEach { conversation in
                    conversation.appendFederationTerminationSystemMessage(
                        domains: [domain, selfUserDomain],
                        sender: selfUser,
                        at: .now
                    )
                    
                    conversation.isForcedReadOnly = true
                }
        }
    }
    
    private func removeConnectedUsers(with domain: String) {
        let connectedUsersPredicate = ZMUser.predicateForConnectedUsers(
            hostedOnDomain: domain
        )
        
        let fetchRequest = ZMUser.sortedFetchRequest(
            with: connectedUsersPredicate
        )
        
        guard let connectedUsers = context.fetchOrAssert(
            request: fetchRequest
        ) as? [ZMUser] else { return }
        
        connectedUsers.forEach { user in
            user.connection = nil
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
