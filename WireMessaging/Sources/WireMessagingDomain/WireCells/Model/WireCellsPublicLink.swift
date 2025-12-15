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

public struct WireCellsPublicLink: Equatable, Hashable, Sendable {
    public let uuid: UUID
    public let url: URL
    public let password: String?
    public let expirationDate: Date?

    package init(uuid: UUID, url: URL, password: String?, expirationDate: Date?) {
        self.uuid = uuid
        self.url = url
        self.password = password
        self.expirationDate = expirationDate
    }
}
