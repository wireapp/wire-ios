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

/// Facilitate access to connections related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
protocol ConnectionsRepositoryProtocol {

    /// Pull self team metadata frmo the server and store locally.

    func pullConnections() async throws
}

struct ConnectionsRepository: ConnectionsRepositoryProtocol {

    // MARK: - Properties

    private let connectionsAPI: any ConnectionsAPI
    private let connectionsLocalStore: any ConnectionsLocalStoreProtocol

    // MARK: - Object lifecycle

    init(
        connectionsAPI: any ConnectionsAPI,
        connectionsLocalStore: any ConnectionsLocalStoreProtocol
    ) {
        self.connectionsAPI = connectionsAPI
        self.connectionsLocalStore = connectionsLocalStore
    }

    // MARK: - Public

    /// Retrieve from backend and store connections locally

    public func pullConnections() async throws {
        let connectionsPager = try await connectionsAPI.getConnections()

        for try await connections in connectionsPager {
            await withThrowingTaskGroup(of: Void.self) { taskGroup in
                for connection in connections {
                    taskGroup.addTask {
                        try await connectionsLocalStore.storeConnection(connection)
                    }
                }
            }
        }
    }
}
