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
import WireCoreCrypto

// TODO [WPB-765]: Ensure that these use cases are only applied to mls conversations

public struct IsUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol {

    private let schedule: NSManagedObjectContext.ScheduledTaskType
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    public init(
        schedule: NSManagedObjectContext.ScheduledTaskType,
        coreCryptoProvider: CoreCryptoProviderProtocol
    ) {
        self.schedule = schedule
        self.coreCryptoProvider = coreCryptoProvider
    }

    public func invoke(
        conversation: ZMConversation,
        user: ZMUser
    ) async throws -> Bool {

        guard let userContext = user.managedObjectContext else {
            throw Error.usersManagedObjectContextNotSet
        }
        guard let conversationContext = conversation.managedObjectContext else {
            throw Error.conversationsManagedObjectContextNotSet
        }

        // if the provided user is the self user ensure that the provided conversation ist the mlsSelfConversation
        let isSelfUser = await userContext.perform(schedule: schedule) { user.isSelfUser }
        if isSelfUser {
            // ensure the conversation is the mls-self-conversation
            let isSelfConversation = await conversationContext.perform(schedule: schedule) {
                ZMConversation.fetchSelfMLSConversation(in: conversationContext)?.remoteIdentifier == conversation.remoteIdentifier
            }
            guard isSelfConversation else {
                throw Error.conversationIsNotTheMLSSelfConversation
            }
        }

        // get the values required for the call to Core Crypto
        let conversationID = await conversationContext.perform(schedule: schedule) { conversation.mlsGroupID?.data }
        guard let conversationID else {
            throw Error.failedToGetMLSGroupID(conversation)
        }
        let (userID, clientCount) = await userContext.perform(schedule: schedule) {
            let userID = user.remoteIdentifier.transportString()
            return (userID, user.allClients.count)
        }

        // make the call to Core Crypto
        let coreCrypto = try await coreCryptoProvider.coreCrypto()
        let identities = try await coreCrypto.perform { coreCrypto in
            let result = try await coreCrypto.getUserIdentities(conversationId: conversationID, userIds: [userID])

            // an empty result means not certified
            guard !result.isEmpty else { return [WireIdentity]() }

            guard let identities = result[userID] else {
                throw Error.failedToGetIdentitiesFromCoreCryptoResult(result, userID)
            }
            return identities
        }

        return !identities.isEmpty && identities.count == clientCount && identities.allSatisfy { $0.status == .valid }
    }
}

extension IsUserE2EICertifiedUseCase {

    enum Error: Swift.Error {
        case usersManagedObjectContextNotSet
        case conversationsManagedObjectContextNotSet
        case conversationIsNotTheMLSSelfConversation
        case failedToGetMLSGroupID(_ conversation: Conversation)
        /// The list of identities cannot be retrieved from the result.
        case failedToGetIdentitiesFromCoreCryptoResult(_ result: [String: [WireIdentity]], _ userID: String)
    }
}
