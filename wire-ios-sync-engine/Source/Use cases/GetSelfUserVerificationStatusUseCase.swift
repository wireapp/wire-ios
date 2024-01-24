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
        guard let userID = await context.perform({
            let selfUser = ZMUser.selfUser(in: context)
            return MLSClientID(user: selfUser)
        }) else {
            assertionFailure("MLSClientID(selfUser) is nil")
            return (false, false)
        }

        guard let conversationID = await context.perform({
            ZMConversation.selfConversation(in: context).mlsGroupID?.data
        }) else {
            assertionFailure("selfConversation.mlsGroupID is nil")
            return (false, false)
        }

        let coreCrypto = try await coreCryptoProvider.coreCrypto(requireMLS: true)
        let result = try await coreCrypto.perform { coreCrypto in
            try await coreCrypto.getUserIdentities(
                conversationId: conversationID,
                userIds: [userID.clientID]
            )
        }

        print(result)
        debugPrint(result)

        fatalError()
    }
}
