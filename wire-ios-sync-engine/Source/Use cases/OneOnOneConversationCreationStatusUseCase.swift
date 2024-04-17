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

public protocol OneOnOneConversationCreationStatusUseCaseProtocol {

    func invoke(userID: QualifiedID) async throws -> OneOnOneConversationCreationStatus

}

public enum OneOnOneConversationCreationStatus {

    case exists(protocol: MessageProtocol, established: Bool?)
    case doesNotExist(protocol: MessageProtocol?)

}

public struct OneOnOneConversationCreationStatusUseCase: OneOnOneConversationCreationStatusUseCaseProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let oneOnOneProtocolSelector: OneOnOneProtocolSelectorInterface
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    // MARK: - Types

    public enum Error: Swift.Error {
        case userNotFound
        case missingGroupID
    }

    // MARK: - Life cycle

    public init(
        context: NSManagedObjectContext,
        oneOnOneProtocolSelector: OneOnOneProtocolSelectorInterface,
        coreCryptoProvider: CoreCryptoProviderProtocol
    ) {
        self.context = context
        self.oneOnOneProtocolSelector = oneOnOneProtocolSelector
        self.coreCryptoProvider = coreCryptoProvider
    }

    // MARK: - Public interface

    public func invoke(userID: QualifiedID) async throws -> OneOnOneConversationCreationStatus {
        let conversation = try await context.perform {
            guard let user = ZMUser.fetch(with: userID, in: context) else {
                throw Error.userNotFound
            }
            return user.oneOnOneConversation
        }

        if let conversation = conversation {
            let messageProtocol = await context.perform { conversation.messageProtocol }

            switch messageProtocol {
            case .proteus:
                return .exists(protocol: .proteus, established: nil)
            case .mls, .mixed:
                guard let groupID = await context.perform({ conversation.mlsGroupID }) else {
                    throw Error.missingGroupID
                }

                let isEstablished = try await isMLSConversationEstablished(groupID: groupID)
                return .exists(protocol: messageProtocol, established: isEstablished)
            }
        } else {
            let messageProtocol = try await oneOnOneProtocolSelector.getProtocolForUser(
                with: userID,
                in: context
            )
            return .doesNotExist(protocol: messageProtocol)
        }
    }

    // MARK: - Helpers

    private func isMLSConversationEstablished(groupID: MLSGroupID) async throws -> Bool {
        try await coreCryptoProvider.coreCrypto().perform {
            await $0.conversationExists(conversationId: groupID.data)
        }
    }

}
