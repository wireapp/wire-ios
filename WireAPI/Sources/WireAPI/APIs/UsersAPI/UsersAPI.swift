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

// sourcery: AutoMockable
/// An API access object for endpoints concerning users.
public protocol UsersAPI {

    /// Get user details for a single user
    ///
    /// - Parameter userID: The id of the user.
    /// - Returns: The user details.

    func getUser(for userID: UserID) async throws -> User

    /// Get user details for a list of users
    ///
    /// - Parameter userIDs: lists of user ids
    /// - Returns: List user details response.

    func getUsers(userIDs: [UserID]) async throws -> UserList
}
