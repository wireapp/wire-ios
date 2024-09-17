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

struct MessageInfo {
    /// list of clients divided per domain and userId
    var listClients: [String : [UUID : [ProteusSessionID]]]
    var missingClientsStrategy: MissingClientsStrategy
    var selfClientID: String
    var nativePush: Bool
    
    
    func allSessionIds() -> [ProteusSessionID] {
        var result = [ProteusSessionID]()
        for (_, userClientIdAndSessionIds) in listClients {
            for (userId, sessionIds) in userClientIdAndSessionIds {
                result.append(contentsOf: sessionIds)
            }
        }
        return result
    }
}

/// Pull out of coredata object info to send a message
struct MessageInfoExtractor {
    var context: NSManagedObjectContext
    
    func infoForTransport(message: GenericMessage, in conversation: ZMConversation) async throws -> MessageInfo {
        let selfUser = await context.perform { ZMUser.selfUser(in: context) }
        let selfClientID = try await selfClientID()
        guard let selfDomain = selfUser.domain else {
            throw MessageEncryptorError.missingSelfDomain
        }
        
        // get the recipients and the missing clientsStrategy
        let (recipients, missingClientsStrategy) = await self.recipients(for: message, selfUser: selfUser, in: conversation)
        
        // get the list of clients
        let clients = await listOfClients(for: recipients, selfDomain: selfDomain, selfClientID: selfClientID)
                
        return MessageInfo(listClients: clients,
                           missingClientsStrategy: missingClientsStrategy,
                           selfClientID: selfClientID,
                           // We do not want to send pushes for delivery receipts.
                           nativePush: !message.hasConfirmation
                )
        
    }
    
    private func selfClientID() async throws -> String {
        let selfClientID = await context.perform {
            ZMUser.selfUser(in: context).selfClient()?.remoteIdentifier
        }
        guard let id = selfClientID else { throw MessageEncryptorError.missingValidSelfClient }
        return id
    }
    
    private func recipients(for message: GenericMessage, selfUser: ZMUser, in conversation: ZMConversation) async -> ([ZMUser : Set<UserClient>], MissingClientsStrategy) {
        let (users, missingClientsStrategy) = await context.perform { message.recipientUsersForMessage(in: conversation, selfUser: selfUser) }
        
        return (await context.perform { users }, missingClientsStrategy)
    }
    
    private func listOfClients(for recipients: [ZMUser : Set<UserClient>], selfDomain: String, selfClientID: String) async -> [String: [UUID: [ProteusSessionID]]] {
        
        let recipientsByDomain = await context.perform {
            Dictionary(grouping: recipients) { element -> String in
                element.key.domain ?? selfDomain
                // is there really a need to keep selfDomain as backup values
            }
        }
        
        var qualifiedUserEntries = [String: [UUID: [ProteusSessionID]]]()
        for (domain, recipients) in recipientsByDomain {

            var userEntries = [UUID: [ProteusSessionID]]()
            for (user, clients) in recipients {
                guard let userId = await context.perform({
                    !user.isAccountDeleted ? user.remoteIdentifier : nil
                }) else { continue }

                let sessionIds = await sessionIds(selfClientID, userClients: clients)
                userEntries[userId] = sessionIds
            }
            qualifiedUserEntries[domain] = userEntries
        }
        return qualifiedUserEntries
    }
    
    private func sessionIds(_ selfClientID: String, userClients: Set<UserClient>) async -> [ProteusSessionID] {
       
        return await context.perform {
            userClients.compactMap {
                guard $0.remoteIdentifier != selfClientID else {
                    // skips self client session
                    return nil
                }
                return $0.proteusSessionID
            }
        }
    }
}
