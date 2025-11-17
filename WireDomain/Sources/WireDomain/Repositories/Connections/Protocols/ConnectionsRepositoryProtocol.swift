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

// sourcery: AutoMockable
/// Facilitate access to connections related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
public protocol ConnectionsRepositoryProtocol {

    /// Pull self team metadata from the server and store locally.

    func pullConnections() async throws

    /// Updates a connection locally.
    ///
    /// - parameters:
    ///     - connection: The connection to update.

    func updateConnection(
        _ connection: Connection
    ) async throws

    /// Mark the connection's conversation to be sync with backend
    /// - Parameter connection: the conversation's connection
    func scheduleToSyncConversation(with connection: Connection) async throws
}
