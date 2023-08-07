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

public protocol FederationTerminationManagerInterface {
    func handleFederationTerminationWith(_ domain: String)
    func handleFederationTerminationBetween(_ domain: String, otherDomain: String)
}

final public class FederationTerminationManager: FederationTerminationManagerInterface {
    private weak var syncContext: NSManagedObjectContext?

    public init(syncContext: NSManagedObjectContext? = nil) {
        self.syncContext = syncContext
    }

    public func handleFederationTerminationWith(_ domain: String) {
        guard let moc = syncContext,
              let selfDomain = ZMUser.selfUser(in: moc).domain else { return }

        markAllOneToOneConversationsAsReadOnly(forDomain: domain)
        removeConnectionRequests(withDomain: domain)
        handleFederationTerminationBetween(selfDomain, otherDomain: domain)
    }

    public func handleFederationTerminationBetween(_ domain: String, otherDomain: String) {
        guard let moc = syncContext else { return }
        let conversations = ZMConversation.allGroupConversationWithSomeDomain(moc: moc)
        let domains = [domain, otherDomain]

        for currentConversation in conversations {
            if domains.contains(currentConversation.domain ?? "") {
                // if conversation hosted on one of domains, then remove only users from the other domain
                let domainsToRemove = domains.filter { $0 != currentConversation.domain ?? "" }
                removeParticipantsFromDomains(domains: domainsToRemove, inConversation: currentConversation)
                addSystemMessageDomainsStoppedFederating(domains: domains, inConversation: currentConversation)
            } else {
                //remove participants from both domains
                guard currentConversation.containsParticipantsFromAllDomains(domains: domains) else { continue }
                removeParticipantsFromDomains(domains: domains, inConversation: currentConversation)
                addSystemMessageDomainsStoppedFederating(domains: domains, inConversation: currentConversation)
            }
        }
        try? moc.save()
    }
}

private extension FederationTerminationManager {

    func markAllOneToOneConversationsAsReadOnly(forDomain domain: String) {
        guard let moc = syncContext,
              let selfDomain = ZMUser.selfUser(in: moc).domain else { return }

        let fetchRequest = ZMUser.sortedFetchRequest(with: ZMUser.predicateForConnectedUsers(inDomain: domain))
        let users = moc.fetchOrAssert(request: fetchRequest) as? [ZMUser] ?? []
        for user in users {
            guard let conversation = user.connection?.conversation else { continue }
            conversation.isForcedReadOnly = true
            addSystemMessageDomainsStoppedFederating(domains: [selfDomain, domain], inConversation: conversation)
        }
    }

    func removeConnectionRequests(withDomain domain: String) {
        guard let moc = syncContext else { return }

        let pendingUsersFetchRequest = ZMUser.sortedFetchRequest(with: ZMUser.predicateForUsersSendAndPendingConnection(inDomain: domain))
        let pendingUsers = moc.fetchOrAssert(request: pendingUsersFetchRequest) as? [ZMUser] ?? []
        for user in pendingUsers {
            user.connection?.status = (user.connection?.status == .pending) ? .ignored : .cancelled
        }
    }

    func removeParticipantsFromDomains(domains: [String], inConversation conversation: ZMConversation) {
        let participants = conversation.localParticipants.filter { domains.contains($0.domain ?? "") }
        conversation.removeParticipantsWithoutUpdatingState(users: participants)
        addSystemMessageAboutRemovedParticipants(participants: participants, inConversation: conversation)
    }

    func addSystemMessageAboutRemovedParticipants(participants: Set<ZMUser>, inConversation conversation: ZMConversation) {
        guard let moc = syncContext else { return }
        let selfUser = ZMUser.selfUser(in: moc)
        conversation.appendParticipantsRemovedAnonymouslySystemMessage(users: participants, sender: selfUser, at: Date())
    }

    func addSystemMessageDomainsStoppedFederating(domains: [String], inConversation conversation: ZMConversation) {
        guard let moc = syncContext else { return }
        let selfUser = ZMUser.selfUser(in: moc)
        conversation.appendDomainsStoppedFederatingSystemMessage(domains: domains, sender: selfUser, at: Date())
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
