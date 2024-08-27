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

import AppIntents
import WireDataModel
import os

@available(iOS 16.0, *)
struct ConversationEntity: AppEntity {

    static var defaultQuery: ConversationEntityQuery { .init() }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: .init(stringLiteral: "Conversation"))
    }

    var displayRepresentation: DisplayRepresentation {
        .init(title: "\(name)")
    }

    var id: QualifiedID
    var name: String
}

@available(iOS 16.0, *)
struct ConversationEntityQuery: EntityQuery {

//    @Dependency
//    var trailManager: TrailDataManager

    func entities(for identifiers: [ConversationEntity.ID]) async throws -> [ConversationEntity] {
        Logger.entityQueryLogging.debug("entities(for: \(identifiers)): ?")
        return identifiers.map { id in
            .init(id: id, name: "\(id)")
        }
    }

    func suggestedEntities() async throws -> [ConversationEntity] {
        [.init(id: .random(), name: "adkslbjsdf")]
    }
}

extension QualifiedID: EntityIdentifierConvertible {

    public var entityIdentifierString: String { "\(uuid.transportString())@\(domain)" }
    public static func entityIdentifier(for entityIdentifierString: String) -> QualifiedID? {

        Logger.entityQueryLogging.debug("entityIdentifier(for: \(entityIdentifierString)) -> ?")

        let elements = entityIdentifierString
            .split(separator: "@")
            .map(String.init)

        guard elements.count == 2, let uuid = UUID(transportString: elements[0]) else { return nil }

        return .init(uuid: uuid, domain: elements[1])
    }
}
