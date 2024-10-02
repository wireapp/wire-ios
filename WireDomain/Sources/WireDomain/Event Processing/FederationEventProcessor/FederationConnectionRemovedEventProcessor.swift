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

import WireAPI
import CoreData
import WireDataModel

/// Process federation connection removed events.

protocol FederationConnectionRemovedEventProcessorProtocol {

    /// Process a federation connection removed event.
    ///
    /// - Parameter event: A federation connection removed event.

    func processEvent(_ event: FederationConnectionRemovedEvent) async throws

}

struct FederationConnectionRemovedEventProcessor: FederationConnectionRemovedEventProcessorProtocol {

    enum Error: Swift.Error {
        case missingDomains(Set<String>)
    }

    let context: NSManagedObjectContext

    func processEvent(_ event: FederationConnectionRemovedEvent) async throws {
        let domains = Array(event.domains)
        
        guard
            domains.count == 2,
            let domain = domains.first,
            let otherDomain = domains.last
        else {
            throw Error.missingDomains(event.domains)
        }

        await removeFederationConnection(between: domain, and: otherDomain)
    }
    
    // MARK: - Private

    /// Removes a federation connection between two specific domains locally.
    /// - Parameter domain: The first domain.
    /// - Parameter otherDomain: The other domain.

    private func removeFederationConnection(
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

}
