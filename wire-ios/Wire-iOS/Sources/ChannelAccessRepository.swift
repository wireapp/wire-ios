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

import WireNetwork
import WireConversationsAPI
import WireConversationsImplementation
import WireDomain
import WireSyncEngine
import WireTransport

class ChannelAccessRepository: ChannelAccessRepositoryProtocol {

    private let conversationID: String
    private let conversationDomain: String
    private let session: ZMUserSession

    init(
        conversationID: String,
        conversationDomain: String,
        session: ZMUserSession
    ) {
        self.conversationID = conversationID
        self.conversationDomain = conversationDomain
        self.session = session
    }

    func updateParticipantPermission(
        to permission: WireConversationsAPI.ChannelAccessLevelPermission
    ) async throws -> WireConversationsAPI.ChannelAccessLevelPermission {

        guard let backendInfoApiVersion = BackendInfo.apiVersion,
              let apiVersion = WireNetwork.APIVersion(rawValue: UInt(backendInfoApiVersion.rawValue)),
              let apiService = session.apiService else {
            throw ChannelAccessError.notEnoughData
        }

        let conversationsAPI = ConversationsAPIBuilder(
            apiService: apiService
        ).makeAPI(for: apiVersion)

        let permission = try await conversationsAPI
            .addChannelPermission(
                conversationID: conversationID,
                conversationDomain: conversationDomain,
                permission: permission.toNetworkPermission()
            )
        return permission.toDomain()
    }
}

extension WireConversationsAPI.ChannelAccessLevelPermission {
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
    func toDomain() -> WireConversationsAPI.ChannelAccessLevelPermission {
        switch self {
        case .admins:
            .admins
        case .everyone:
            .everyone
        }
    }
}
