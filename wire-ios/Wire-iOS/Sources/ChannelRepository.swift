//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireDomain
import WireMessagingDomain
import WireNetwork
import WireSyncEngine
import WireTransport

class ChannelRepository: ChannelRepositoryProtocol {
    private let api: any ConversationsAPI
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let featureConfigLocalStore: any FeatureConfigLocalStoreProtocol
    private let conversationID: String
    private let conversationDomain: String

    init(
        api: any ConversationsAPI,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        featureConfigLocalStore: any FeatureConfigLocalStoreProtocol,
        conversationID: String,
        conversationDomain: String
    ) {
        self.api = api
        self.conversationLocalStore = conversationLocalStore
        self.featureConfigLocalStore = featureConfigLocalStore
        self.conversationID = conversationID
        self.conversationDomain = conversationDomain
    }

    func updateParticipantPermission(
        to permission: WireMessagingDomain.ChannelAccessLevelPermission
    ) async throws -> WireMessagingDomain.ChannelAccessLevelPermission {

        let permission = try await api
            .addChannelPermission(
                conversationID: conversationID,
                conversationDomain: conversationDomain,
                permission: permission.toNetworkPermission()
            )
        return permission.toDomain()
    }

    // TODO: [WPB-18347] - call endpoint when backend ready - PUT /conversations/{cnv_domain}/{cnv_id}/history and store history depth to local store
    func updateHistoryDepth(_ historyDepth: String?) async throws {
        // let historyDepth = api.updateChannelHistoryDepth(
        // conversationID: conversationID,
        // conversationDomain: conversationDomain,
        // historyDepth: WireAPI.ChannelHistoryDepth)

//        store.storeConversation(
//            historyDepth: historyDepth,
//            conversationID: conversationID,
//            conversationDomain: conversationDomain
//        )

        // return historyDepth
    }

    func isConferenceCallingFeatureEnabled() async throws -> Bool {
        let confCallingFeature = try await featureConfigLocalStore.fetchFeature(
            name: .conferenceCalling
        )

        return await featureConfigLocalStore.isFeatureEnabled(
            feature: confCallingFeature
        )
    }
}

extension WireMessagingDomain.ChannelAccessLevelPermission {
    func toNetworkPermission() -> WireNetwork.ChannelPermission {
        switch self {
        case .admins:
            .admins
        case .everyone:
            .everyone
        }
    }
}

extension WireNetwork.ChannelPermission {
    func toDomain() -> WireMessagingDomain.ChannelAccessLevelPermission {
        switch self {
        case .admins:
            .admins
        case .everyone:
            .everyone
        }
    }
}
