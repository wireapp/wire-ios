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


public struct WireCellsQualifiedID: Codable, Equatable, Hashable, Identifiable, Sendable {

    package let domain: String
    package let value: String

    public var id: String {
        return "\(domain)/\(value)"
    }

    package init(domain: String, value: String) {
        self.domain = domain
        self.value = value
    }
}

extension WireCellsQualifiedID: CustomStringConvertible {
    public var description: String {
        return "\(domain)/\(value)"
    }
}

extension WireCellsQualifiedID: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "QualifiedID(domain: \(domain), value: \(value))"
    }
}
