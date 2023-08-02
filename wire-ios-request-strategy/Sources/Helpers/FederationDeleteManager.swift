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

final public class FederationDeleteManager {
    private weak var syncContext: NSManagedObjectContext?

    public init(syncContext: NSManagedObjectContext? = nil) {
        self.syncContext = syncContext
    }

    public func backendStoppedFederatingWithDomain(domain: String) {
        guard let moc = syncContext,
              let selfDomain = ZMUser.selfUser(in: moc).domain else { return }

        // search all conversations hosted on domain and remove participants from selfDomain
        removeAllParticipantsFromDomain(selfDomain, fromConversationsOnDomain: domain)

        // search all conversation hosted on selfDomain that have participants from domain and remove them
        removeAllParticipantsFromDomain(domain, fromConversationsOnDomain: selfDomain)


        // find all conversations where participants are from domain and selfDomain
        let conversations = ZMConversation.existingConversationsHostedOnDomainDifferentThan(domain: selfDomain, moc: moc)
        let domainsThatStoppedFederating = [selfDomain, domain]
        let filteredConvesations = conversations.filter { $0.containsParticipantsFromAllDomains(domains: domainsThatStoppedFederating)}
        for currentConversation in filteredConvesations {
            removeParticipantsFromDomains(domains: [domain, selfDomain], inConversation: currentConversation)
        }

        //  search all 1:1 conversations with users from domain and mark as readOnly
        let fetchRequest = ZMUser.sortedFetchRequest(with: ZMUser.predicateForConnectedUsers(inDomain: domain))
        let users = moc.fetchOrAssert(request: fetchRequest) as? [ZMUser] ?? []
        for user in users {
            guard let conversation = user.connection?.conversation else { continue }
            conversation.isForcedReadOnly = true
        }


        //  search all users requesting connection from domain and remove request
        let pendingFetchRequest = ZMUser.sortedFetchRequest(with: ZMUser.predicateForUsersPendingConnection(inDomain: domain))
        let pendingUsers = moc.fetchOrAssert(request: pendingFetchRequest) as? [ZMUser] ?? []
        for user in pendingUsers {
            user.conne
        }

    }

    func domainsStoppedFederating(domains: [String]) {
        guard let moc = syncContext else { return }
        let conversations = ZMConversation.allGroupConversationWithDomain(moc: moc)

        for currentConversation in conversations {
            if domains.contains(currentConversation.domain ?? "") {
                let domainsToRemove = domains.filter { $0 != currentConversation.domain ?? "" }
                removeParticipantsFromDomains(domains: domainsToRemove, inConversation: currentConversation)
            } else {
                guard currentConversation.containsParticipantsFromAllDomains(domains: domains) else { continue }
                removeParticipantsFromDomains(domains: domains, inConversation: currentConversation)
            }
        }
    }
}

extension FederationDeleteManager {

    func removeParticipantsFromDomains(domains: [String], inConversation conversation: ZMConversation) {
        let participants = conversation.localParticipants.filter { domains.contains($0.domain ?? "") }
        conversation.removeParticipantsWithoutUpdatingState(users: participants)
        addSystemMessageAboutRemovedParticipants(participants: participants, inConversation: conversation)
    }

    func removeAllParticipantsFromDomain(_ participantsDomain: String, fromConversationsOnDomain conversationDomain: String) {
        guard let moc = syncContext else { return }
        let conversations = ZMConversation.existingConversationsHostedOnDomain(domain: conversationDomain,
                                                                               moc: moc)
        for conversation in conversations {
            deleteAllParticipantsFromDomain(domain: participantsDomain,
                                            inConversation: conversation,
                                            selfUser: ZMUser.selfUser(in: moc))
        }
    }

    func deleteAllParticipantsFromDomain(domain: String, inConversation conversation: ZMConversation, selfUser: ZMUser) {
        let participantsFromDomain = conversation.localParticipants.filter { $0.domain == domain }
        conversation.removeParticipantsWithoutUpdatingState(users: participantsFromDomain)
        addSystemMessageAboutRemovedParticipants(participants: participantsFromDomain, inConversation: conversation)
    }

    func addSystemMessageAboutRemovedParticipants(participants: Set<ZMUser>, inConversation conversation: ZMConversation) {
        guard let moc = syncContext else { return }
        let selfUser = ZMUser.selfUser(in: moc)

        // TODO: create new system message "xyz was removed from conversation" instead of current "you removed XYZ from conversation"
        conversation.appendParticipantsRemovedSystemMessage(users: participants, sender: selfUser, at: Date())
    }
}

fileprivate extension ZMConversation {

    func containsParticipantsFromAllDomains(domains: [String]) -> Bool {
        for currentDomain in domains {
            guard localParticipants.contains(where: { $0.domain == currentDomain }) else { return false }
        }
        return true
    }
}
