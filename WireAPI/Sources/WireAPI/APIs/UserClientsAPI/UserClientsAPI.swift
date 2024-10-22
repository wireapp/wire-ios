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

// sourcery: AutoMockable
/// An API access object for endpoints concerning user clients.
public protocol UserClientsAPI {

    /// Get self user registered clients
    /// - returns: A list of self user clients.

    func getSelfClients() async throws -> [SelfUserClient]

    /// Get clients for qualified users.
    ///
    /// - parameter userIDs: A list of user ids.
    /// - returns: A list of clients for a given user ID on a given domain.

    func getClients(for userIDs: Set<UserID>) async throws -> [OtherUserClients]
}
