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

// sourcery: AutoMockable
/// Determines if the self user has a valid E2EI certificate on all clients.
public protocol IsSelfUserE2EICertifiedUseCaseProtocol {
    /// Returns `true` if all clients of the self user have valid E2EI certificates.
    func invoke() async throws -> Bool
}

public struct IsSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol {

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

    public func invoke() async throws -> Bool {
        let (conversationID, userID, clientCount) = try await context.perform(schedule: schedule) {
            // conversationID
            guard let selfConversation = ZMConversation.fetchSelfMLSConversation(in: context) else {
                throw Error.couldNotFetchMLSSelfConversation
            }
            guard let mlsGroupID = selfConversation.mlsGroupID else {
                throw Error.failedToGetMLSGroupID(selfConversation)
            }
            // userID
            let selfUser = ZMUser.selfUser(in: context)
            guard
                let qualifiedID = selfUser.qualifiedID,
                let userID = Optional(qualifiedID.uuid.transportString()) // TODO: [WPB-765]: workaround for a bug in core crypto, should be fixed mid february 2024, no JIRA ticket
                // let userID = MLSUserID(userID: qualifiedID.uuid.transportString(), domain: qualifiedID.domain).rawValue
            else {
                throw Error.failedToGetSelfUserID
            }
            return (mlsGroupID, userID, selfUser.allClients.count)
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

extension IsSelfUserE2EICertifiedUseCase {

    enum Error: Swift.Error {
        case failedToGetSelfUserID
        case couldNotFetchMLSSelfConversation
        case failedToGetMLSGroupID(_ conversation: Conversation)
        /// The list of identities cannot be retrieved from the result.
        case failedToGetIdentitiesFromCoreCryptoResult(_ result: [String: [WireIdentity]], _ userID: String)
    }
}
