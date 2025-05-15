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

public struct WireCellsConversationID: Codable, Equatable, Hashable, Identifiable, Sendable {

    public let domain: String
    public let uuid: UUID

    public var id: String {
        "\(uuid.uuidString)@\(domain)"
    }

    public var pydioQualifiedID: String {
        "\(uuid.uuidString)@\(domain)"
    }

    package init(domain: String, uuid: UUID) {
        self.domain = domain
        self.uuid = uuid
    }

    public init?(string: String) {
        // The CellsSDK provides the qualifiedID as a string in the format `uuid@domain`
        let components = string.split(separator: "@")
        guard components.count == 2, let uuid = UUID(uuidString: String(components[1])) else {
            return nil
        }
        self.domain = String(components[0])
        self.uuid = uuid
    }
}

extension WireCellsConversationID: CustomStringConvertible {
    public var description: String {
        "\(uuid.uuidString)@\(domain)"
    }
}

extension WireCellsConversationID: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ConversationID(domain: \(domain), uuid: \(uuid.uuidString))"
    }
}
