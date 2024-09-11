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

public struct QualifiedID: Codable, Hashable, CustomDebugStringConvertible {

    enum CodingKeys: String, CodingKey {
        case uuid = "id"
        case domain
    }

    public let uuid: UUID
    public let domain: String

    public init(uuid: UUID, domain: String) {
        self.uuid = uuid
        self.domain = domain
    }

    public var debugDescription: String {
        return "\(uuid)@\(domain)"
    }

}

extension QualifiedID: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        "\(self.uuid.safeForLoggingDescription) - \(self.domain.redactedAndTruncated(maxVisibleCharacters: 4, length: 7))"
    }
}

public extension ZMUser {

    var qualifiedID: QualifiedID? {
        guard
            let context = managedObjectContext,
            let uuid = remoteIdentifier,
            let domain = domain ?? ZMUser.selfUser(in: context).domain
        else {
            return nil
        }

        return QualifiedID(uuid: uuid, domain: domain)
    }

}

public extension ZMConversation {

    var qualifiedID: QualifiedID? {
        guard
            let uuid = remoteIdentifier,
            let domain = domain ?? BackendInfo.domain
        else {
            return nil
        }

        return QualifiedID(uuid: uuid, domain: domain)
    }

}

public extension Collection where Element == ZMUser {

    var qualifiedUserIDs: [QualifiedID]? {
        let list = compactMap(\.qualifiedID)

        return list.count == count ? list : nil
    }

}

public extension Collection where Element == ZMConversation {

    var qualifiedIDs: [QualifiedID]? {
        let list = compactMap(\.qualifiedID)

        return list.count == count ? list : nil
    }

}

// TODO: [WPB-11016] Move this test code from production targets
#if DEBUG
public extension QualifiedID {

    static func random() -> QualifiedID {
        return QualifiedID(
            uuid: UUID(),
            domain: .randomDomain()
        )
    }

}
#endif
