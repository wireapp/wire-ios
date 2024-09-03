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
import WireAPI
import WireDataModel

// sourcery: AutoMockable
/// Facilitate access to conversations related domain objects.
public protocol ConversationRepositoryProtocol {

    /// Fetches and persists all conversations

    func pullConversations() async throws

}

public final class ConversationRepository: ConversationRepositoryProtocol {

    public struct BackendInfo {
        let domain: String
        let isFederationEnabled: Bool
    }

    // MARK: - Properties

    private let conversationsAPI: any ConversationsAPI
    private let conversationsLocalStore: any ConversationLocalStoreProtocol
    private let backendInfo: BackendInfo

    // MARK: - Object lifecycle

    public init(
        conversationsAPI: any ConversationsAPI,
        conversationsLocalStore: any ConversationLocalStoreProtocol,
        backendInfo: BackendInfo
    ) {
        self.conversationsAPI = conversationsAPI
        self.conversationsLocalStore = conversationsLocalStore
        self.backendInfo = backendInfo
    }

    // MARK: - Public

    public func pullConversations() async throws {
        var qualifiedIds: [WireAPI.QualifiedID]

        if let result = try? await conversationsAPI.getLegacyConversationIdentifiers() { /// only for api v0 (see `ConversationsAPIV0` method comment)
            let uuids = try await result.reduce([UUID](), +)
            qualifiedIds = uuids.map { WireAPI.QualifiedID(uuid: $0, domain: backendInfo.domain) }
        } else {
            /// fallback to api versions > v0.
            let ids = try await conversationsAPI.getConversationIdentifiers()
            qualifiedIds = try await ids.reduce([WireAPI.QualifiedID](), +)
        }

        let conversationList = try await conversationsAPI.getConversations(for: qualifiedIds)

        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            let foundConversations = conversationList.found
            let missingConversationsQualifiedIds = conversationList.notFound
            let failedConversationsQualifiedIds = conversationList.failed

            for conversation in foundConversations {
                taskGroup.addTask { [self] in
                    await conversationsLocalStore.storeConversation(
                        conversation,
                        isFederationEnabled: backendInfo.isFederationEnabled
                    )
                }
            }

            for id in missingConversationsQualifiedIds {
                taskGroup.addTask { [self] in
                    await conversationsLocalStore.storeConversationNeedsBackendUpdate(
                        true,
                        qualifiedId: id
                    )
                }
            }

            for id in failedConversationsQualifiedIds {
                taskGroup.addTask { [self] in
                    await conversationsLocalStore.storeFailedConversation(
                        withQualifiedId: id
                    )
                }
            }
        }
    }

}
