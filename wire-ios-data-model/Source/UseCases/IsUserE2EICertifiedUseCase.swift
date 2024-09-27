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

// MARK: - IsUserE2EICertifiedUseCase

public struct IsUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol {
    // MARK: Lifecycle

    public init(
        schedule: NSManagedObjectContext.ScheduledTaskType,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        featureRepository: FeatureRepositoryInterface,
        featureRepositoryContext: NSManagedObjectContext
    ) {
        self.schedule = schedule
        self.coreCryptoProvider = coreCryptoProvider
        self.featureRepository = featureRepository
        self.featureRepositoryContext = featureRepositoryContext
    }

    // MARK: Public

    public func invoke(
        conversation: ZMConversation,
        user: ZMUser
    ) async throws -> Bool {
        let isE2EIEnabled = await featureRepositoryContext.perform {
            featureRepository.fetchE2EI().isEnabled
        }
        guard isE2EIEnabled else {
            return false
        }

        guard let userContext = user.managedObjectContext else {
            throw Error.usersManagedObjectContextNotSet
        }
        guard let conversationContext = conversation.managedObjectContext else {
            throw Error.conversationsManagedObjectContextNotSet
        }

        // get the values required for the call to Core Crypto
        let (conversationID, mlsGroupID) = await conversationContext.perform(schedule: schedule) {
            (conversation.remoteIdentifier!, conversation.mlsGroupID?.data)
        }
        guard let mlsGroupID else {
            throw Error.failedToGetMLSGroupID(conversationID)
        }
        let userID = await userContext.perform(schedule: schedule) {
            user.remoteIdentifier.transportString()
        }

        // make the call to Core Crypto
        let coreCrypto = try await coreCryptoProvider.coreCrypto()
        let userIdentities = try await coreCrypto.perform { coreCrypto in
            // get MLS group members
            let allUserIdentities = try await coreCrypto.getUserIdentities(
                conversationId: mlsGroupID,
                userIds: [userID]
            )

            // an empty result means not certified
            guard !allUserIdentities.isEmpty else {
                return [WireIdentity]()
            }

            guard let userIdentities = allUserIdentities[userID] else {
                throw Error.failedToGetIdentitiesFromCoreCryptoResult(allUserIdentities, userID)
            }
            return userIdentities
        }

        return !userIdentities.isEmpty && userIdentities
            .allSatisfy { $0.status == .valid && $0.credentialType == .x509 }
    }

    // MARK: Private

    private let schedule: NSManagedObjectContext.ScheduledTaskType
    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let featureRepository: FeatureRepositoryInterface
    /// The `featureRepository` operates on a context, so every operation must be dispatched
    /// on that context's queue. Since `FeatureRepositoryInterface` doesn't contain any
    /// `context` property, we inject the context here.
    private let featureRepositoryContext: NSManagedObjectContext
}

// MARK: IsUserE2EICertifiedUseCase.Error

extension IsUserE2EICertifiedUseCase {
    enum Error: Swift.Error {
        case usersManagedObjectContextNotSet
        case conversationsManagedObjectContextNotSet
        case failedToGetMLSGroupID(_ conversationID: UUID)
        /// The list of identities cannot be retrieved from the result.
        case failedToGetIdentitiesFromCoreCryptoResult(_ result: [String: [WireIdentity]], _ userID: String)
    }
}
