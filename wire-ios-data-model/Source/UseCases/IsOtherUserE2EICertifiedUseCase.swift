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

public struct IsOtherUserE2EICertifiedUseCase: IsOtherUserE2EICertifiedUseCaseProtocol {

    private let context: NSManagedObjectContext
    private let schedule: NSManagedObjectContext.ScheduledTaskType
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    public init(
        context: NSManagedObjectContext,
        schedule: NSManagedObjectContext.ScheduledTaskType,
        coreCryptoProvider: CoreCryptoProviderProtocol
    ) {
        self.context = context
        self.schedule = schedule
        self.coreCryptoProvider = coreCryptoProvider
    }

    public func invoke(
        conversation: MLSConversation,
        user: UserType
    ) async throws -> Bool {
        let (conversationID, userID, clientCount) = try await context.perform(schedule: schedule) {
            // conversationID
            guard let mlsGroupID = conversation.mlsGroupID else {
                throw Error.failedToGetMLSGroupID(conversation)
            }
            // userID
            let userID = user.remoteIdentifier.transportString()
            return (mlsGroupID, userID, user.allClients.count)
        }

        let coreCrypto = try await coreCryptoProvider.coreCrypto()
        let identities = try await coreCrypto.perform { coreCrypto in
            let result = try await coreCrypto.getUserIdentities(
                conversationId: conversationID.data,
                userIds: [userID]
            )
            guard !result.isEmpty else { return [WireIdentity]() }
            guard let identities = result[userID] else {
                throw Error.failedToGetIdentitiesFromCoreCryptoResult(result, userID)
            }
            return identities
        }

        return !identities.isEmpty && identities.count == clientCount && identities.allSatisfy { $0.status == .valid }
    }
}

extension IsOtherUserE2EICertifiedUseCase {

    enum Error: Swift.Error {
        case failedToGetMLSGroupID(_ conversation: Conversation)
        /// The list of identities cannot be retrieved from the result.
        case failedToGetIdentitiesFromCoreCryptoResult(_ result: [String: [WireIdentity]], _ userID: String)
    }
}
