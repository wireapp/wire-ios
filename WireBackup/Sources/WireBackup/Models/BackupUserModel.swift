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

public typealias BackupUserModel = UserBackupModel

public struct UserBackupModel: Codable, Hashable, Sendable {
    public typealias ID = QualifiedID

    public var id: ID
    public var name: String
    public var handle: String

    public init(
        id: ID,
        name: String,
        handle: String
    ) {
        self.id = id
        self.name = name
        self.handle = handle
    }

}
