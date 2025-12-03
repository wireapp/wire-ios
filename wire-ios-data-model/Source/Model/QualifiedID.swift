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

import Foundation

public struct QualifiedID: Codable, Equatable, Hashable, CustomDebugStringConvertible, Sendable {

    enum CodingKeys: String, CodingKey {
        case uuid = "id"
        case domain
    }

    public let uuid: UUID
    public let domain: String

    public init?(rawValue: String) {
        let components = rawValue.split(
            separator: "@",
            omittingEmptySubsequences: false
        ).map(String.init)

        guard components.count == 2,
              let uuid = UUID(uuidString: components[0])
        else {
            return nil
        }

        self.init(uuid: uuid, domain: components[1])
    }

    public init(uuid: UUID, domain: String) {
        self.uuid = uuid
        self.domain = domain
    }

    public var debugDescription: String {
        "\(uuid)@\(domain)"
    }

}

extension QualifiedID: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        "\(uuid.uuidString.lowercased()) - \(domain)"
    }
}

public protocol HasQualifiedID {
    var qualifiedID: WireDataModel.QualifiedID? { get }
}

extension ZMUser: HasQualifiedID {

    public var qualifiedID: QualifiedID? {
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

extension ZMConversation: HasQualifiedID {

    public var qualifiedID: QualifiedID? {
        guard
            let uuid = remoteIdentifier,
            let domain = domain ?? managedObjectContext?.localDomain
        else {
            return nil
        }

        return QualifiedID(uuid: uuid, domain: domain)
    }

}

public extension Collection<ZMUser> {

    var qualifiedUserIDs: [QualifiedID]? {
        let list = compactMap(\.qualifiedID)

        return list.count == count ? list : nil
    }

}

public extension Collection<ZMConversation> {

    var qualifiedIDs: [QualifiedID]? {
        let list = compactMap(\.qualifiedID)

        return list.count == count ? list : nil
    }

}

// TODO: [WPB-11016] Move this test code from production targets
#if DEBUG
    public extension QualifiedID {

        static func random() -> QualifiedID {
            QualifiedID(
                uuid: UUID(),
                domain: .randomDomain()
            )
        }

    }
#endif
