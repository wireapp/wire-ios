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

internal import Foundation
import WireFoundation

/// Fully qualified identifier in a federated environment.

public typealias QualifiedID = WireFoundation.QualifiedID

struct QualifiedIDV0: Hashable, Equatable, Sendable, Codable, ToAPIModelConvertible {

    public let uuid: UUID
    public let domain: String

    public init(
        uuid: UUID,
        domain: String
    ) {
        self.uuid = uuid
        self.domain = domain
    }

    enum CodingKeys: String, CodingKey {
        case uuid = "id"
        case domain
    }

    func toAPIModel() -> QualifiedID {
        QualifiedID(id: uuid, domain: domain)
    }
}

extension QualifiedID: ToNetworkConvertible {
    func toNetworkModel() -> QualifiedIDV0 {
        QualifiedIDV0(uuid: id, domain: domain)
    }
}
