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

public import WireFoundation

// sourcery: AutoMockable
public protocol UserStoreProtocol: Sendable {
    associatedtype UserEntity: UserEntityProtocol

    /// Returns the number of all stored users in the local data store, including deleted ones.
    func totalUserCount() async throws -> Int

    /// Returns the IDs of all users stored in the local database, including deleted ones.
    func fetchAllUserIDs() async throws -> Set<QualifiedID>

    /// Returns all users stored in the local database, including deleted ones.
    func fetchAllUsers() async throws -> [UserEntity]

    /// Adds a user from the backup file to the local data store.
    func addUser(id: QualifiedID, name: String, handle: String) async throws

}
