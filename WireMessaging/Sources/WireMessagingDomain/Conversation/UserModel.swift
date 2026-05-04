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

public import Foundation

// To be refined later
public struct UserModel: Sendable {

    // 'objectID' to abstract id from data layer hide behind abstract 'any Sendable'
    // used as a way to map domain models back to data models
    public let objectID: any Sendable

    public let remoteIdentifier: UUID
    public let name: String?
    public let handle: String?

    public init(
        objectID: any Sendable,
        remoteIdentifier: UUID,
        name: String?,
        handle: String?
    ) {
        self.remoteIdentifier = remoteIdentifier
        self.name = name
        self.handle = handle
        self.objectID = objectID
    }
}
