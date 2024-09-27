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
import WireDataModel

// sourcery: AutoMockable
public protocol CheckOneOnOneConversationIsReadyUseCaseProtocol {
    /// Checks if there is a one-on-one conversation ready to be used for a given user.
    /// Will return `false` if there is no conversation or if there's an `mls` conversation that isn't established
    ///
    /// - Parameter userID: The qualified ID of the user to check the one on one conversation for
    /// - Returns: Whether the one on one conversation is ready.
    func invoke(userID: QualifiedID) async throws -> Bool
}

public enum CheckOneOnOneConversationIsReadyError: Error, Equatable {
    case userNotFound
    case missingGroupID
}

struct CheckOneOnOneConversationIsReadyUseCase: CheckOneOnOneConversationIsReadyUseCaseProtocol {
    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    // MARK: - Life cycle

    public init(
        context: NSManagedObjectContext,
        coreCryptoProvider: CoreCryptoProviderProtocol
    ) {
        self.context = context
        self.coreCryptoProvider = coreCryptoProvider
    }

    // MARK: - Public interface

    public func invoke(userID: QualifiedID) async throws -> Bool {
        let conversation = try await context.perform {
            guard let user = ZMUser.fetch(with: userID, in: context) else {
                throw CheckOneOnOneConversationIsReadyError.userNotFound
            }
            return user.oneOnOneConversation
        }

        if let conversation {
            let messageProtocol = await context.perform { conversation.messageProtocol }

            switch messageProtocol {
            case .proteus:
                return true

            case .mls:
                guard let groupID = await context.perform({ conversation.mlsGroupID }) else {
                    throw CheckOneOnOneConversationIsReadyError.missingGroupID
                }

                return try await isMLSConversationEstablished(groupID: groupID)

            case .mixed:
                // Message protocol for one to one conversations should never be mixed
                assertionFailure("Message protocol for one to one conversations should never be mixed")
                return false
            }
        } else {
            return false
        }
    }

    // MARK: - Helpers

    private func isMLSConversationEstablished(groupID: MLSGroupID) async throws -> Bool {
        try await coreCryptoProvider.coreCrypto().perform {
            await $0.conversationExists(conversationId: groupID.data)
        }
    }
}
