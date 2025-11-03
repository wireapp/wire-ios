//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireDataModel
import WireLegacyLogging
import WireNetwork

public class ConversationLabelsRepository: ConversationLabelsRepositoryProtocol {

    // MARK: - Properties

    private let userPropertiesAPI: any UserPropertiesAPI
    private let conversationLabelsLocalStore: any ConversationLabelsLocalStoreProtocol
    private let logger = WireLogger(tag: "conversation-labels")

    private let pullConversationLabelsSync: PullConversationLabelsSync

    // MARK: - Object lifecycle

    init(
        userPropertiesAPI: any UserPropertiesAPI,
        conversationLabelsLocalStore: any ConversationLabelsLocalStoreProtocol
    ) {
        self.userPropertiesAPI = userPropertiesAPI
        self.conversationLabelsLocalStore = conversationLabelsLocalStore
        self.pullConversationLabelsSync = PullConversationLabelsSync(
            api: userPropertiesAPI,
            store: conversationLabelsLocalStore
        )
    }

    // MARK: - Public

    public func pullConversationLabels() async throws {
        try await pullConversationLabelsSync.pull()
    }

    public func updateConversationLabels(
        _ conversationLabels: [ConversationLabel]
    ) async throws {
        let localLabels = conversationLabels.map {
            $0.toDomainModel()
        }

        try await conversationLabelsLocalStore.setLabels(localLabels)
    }

}
