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

import Foundation
import WireDataModel
import WireNetwork

public struct ConnectionsRepository: ConnectionsRepositoryProtocol {

    // MARK: - Properties

    private let connectionsAPI: any ConnectionsAPI
    private let connectionsLocalStore: any ConnectionsLocalStoreProtocol

    private let pullUserConnectionsSync: PullUserConnectionsSync

    // MARK: - Object lifecycle

    init(
        connectionsAPI: any ConnectionsAPI,
        connectionsLocalStore: any ConnectionsLocalStoreProtocol
    ) {
        self.connectionsAPI = connectionsAPI
        self.connectionsLocalStore = connectionsLocalStore
        self.pullUserConnectionsSync = PullUserConnectionsSync(
            api: connectionsAPI,
            store: connectionsLocalStore
        )
    }

    // MARK: - Public

    /// Retrieve from backend and store connections locally

    public func pullConnections() async throws {
        try await pullUserConnectionsSync.pull()
    }

    public func updateConnection(
        _ connection: Connection
    ) async throws {
        try await connectionsLocalStore.storeConnection(connection.toDomainModel())
    }

    public func scheduleToSyncConversation(with connection: Connection) async throws {
        try await connectionsLocalStore.markConversationAsNeedUpdatedFromBackend(connection.toDomainModel())
    }
}
