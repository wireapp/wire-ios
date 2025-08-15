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

public import Foundation

public struct UserModel: Sendable {
    // To be refined later
    public let remoteIdentifier: UUID
    public let name: String?
    public let handle: String?

    public init(remoteIdentifier: UUID, name: String?, handle: String?) {
        self.remoteIdentifier = remoteIdentifier
        self.name = name
        self.handle = handle
    }

}
