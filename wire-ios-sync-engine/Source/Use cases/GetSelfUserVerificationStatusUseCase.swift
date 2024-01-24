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
public protocol GetSelfUserVerificationStatusUseCaseProtocol {
    func invoke() async throws -> (isMLSCertified: Bool, isProteusVerified: Bool)
}

public struct GetSelfUserVerificationStatusUseCase: GetSelfUserVerificationStatusUseCaseProtocol {

    private let context: NSManagedObjectContext
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    public init(
        context: NSManagedObjectContext,
        coreCryptoProvider: CoreCryptoProviderProtocol
    ) {
        self.context = context
        self.coreCryptoProvider = coreCryptoProvider
    }

    public func invoke() async throws -> (isMLSCertified: Bool, isProteusVerified: Bool) {
        var isMLSCertified = false

        let (selfUserID, isProteusVerified) = await context.perform { () -> (MLSClientID?, Bool) in
            guard let selfClient = ZMUser.selfUser(in: context).selfClient() else { return (.none, false) }
            return (MLSClientID(userClient: selfClient), selfClient.verified)
        }
        guard let selfUserID else {
            assertionFailure("MLSClientID(selfUser.selfClient()) is nil")
            return (isMLSCertified, isProteusVerified)
        }

        guard let conversationID = await context.perform({
            ZMConversation.fetchSelfMLSConversation(in: context)?.mlsGroupID?.data
        }) else {
            assertionFailure("selfConversation?.mlsGroupID is nil")
            return (isMLSCertified, isProteusVerified)
        }

        let coreCrypto = try await coreCryptoProvider.coreCrypto(requireMLS: true)
        let result = try await coreCrypto.perform { coreCrypto in
            try await coreCrypto.getUserIdentities(
                conversationId: conversationID,
                userIds: [selfUserID.clientID]
            )
        }
        guard let identities = result[selfUserID.clientID] else { return (isMLSCertified, isProteusVerified) }

        isMLSCertified = identities.allSatisfy { $0.status == .valid }

        return (isMLSCertified, isProteusVerified)
    }
}

/*

// sourcery: AutoMockable
public protocol GetUserVerificationStatusUseCaseProtocol {
    func invoke(
        conversation: ZMConversation,
        users: [UserType]
    ) async throws -> [(isMLSCertified: Bool, isProteusVerified: Bool)]
}

public struct GetUserVerificationStatusUseCase: GetUserVerificationStatusUseCaseProtocol {

    private let context: NSManagedObjectContext
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    public init(
        context: NSManagedObjectContext,
        coreCryptoProvider: CoreCryptoProviderProtocol
    ) {
        self.context = context
        self.coreCryptoProvider = coreCryptoProvider
    }

    public func invoke(
        conversation: ZMConversation,
        users: [UserType]
    ) async throws -> [(isMLSCertified: Bool, isProteusVerified: Bool)] {
        fatalError()
    }
    /*
    public func invoke() async throws -> (isMLSCertified: Bool, isProteusVerified: Bool) {
        var isMLSCertified = false
        var isProteusVerified = false

        let (selfClient, selfUserID) = await context.perform { () -> (UserClient?, MLSClientID?) in
            guard let selfClient = ZMUser.selfUser(in: context).selfClient() else { return (.none, .none) }
            return (selfClient, MLSClientID(userClient: selfClient))
        }

        guard let selfClient else {
            assertionFailure("ZMUser.selfUser(in: context).selfClient() is nil")
            return (isMLSCertified, isProteusVerified)
        }

        isProteusVerified = selfClient.verified

        guard let selfUserID else {
            assertionFailure("MLSClientID(selfUser) is nil")
            return (isMLSCertified, isProteusVerified)
        }

        guard let conversationID = await context.perform({
            ZMConversation.fetchSelfMLSConversation(in: context)?.mlsGroupID?.data
        }) else {
            assertionFailure("selfConversation.mlsGroupID is nil")
            return (isMLSCertified, isProteusVerified)
        }

        let coreCrypto = try await coreCryptoProvider.coreCrypto(requireMLS: true)
        let result = try await coreCrypto.perform { coreCrypto in
            try await coreCrypto.getUserIdentities(
                conversationId: conversationID,
                userIds: [selfUserID.clientID]
            )
        }
        guard let identities = result[selfUserID.clientID] else { return (isMLSCertified, isProteusVerified) }

        isMLSCertified = identities.allSatisfy { $0.status == .valid }

        return (isMLSCertified, isProteusVerified)
    }
     */
}
*/
