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
import os
import WireDataModel

@available(iOS 16, *)
struct OpenWireIntent: OpenIntent {

    static let title = LocalizedStringResource(stringLiteral: "Open Wire on selected Account")

    @Parameter(title: "Account", description: "The account the app should be switched to after opening.")
    var target: AccountEntity
}

@available(iOS 16.0, *)
struct AccountEntity: AppEntity {

    static var defaultQuery: AccountEntityQuery { .init() }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: .init(stringLiteral: "Account"))
    }

    var displayRepresentation: DisplayRepresentation {
        .init(title: "\(name)")
    }

    var id: QualifiedID
    var name: String
}

@available(iOS 16.0, *)
struct AccountEntityQuery: EntityQuery {

//    @Dependency
//    var trailManager: TrailDataManager

    func entities(for identifiers: [AccountEntity.ID]) async throws -> [AccountEntity] {
        Logger.openWireIntent.debug("entities(for: \(identifiers)): ?")
        return identifiers.map { id in
            .init(id: id, name: "\(id)")
        }
    }

    func suggestedEntities() async throws -> [AccountEntity] {
        [.init(id: .random(), name: "adkslbjsdf")]
    }
}

@available(iOS 16, *)
extension Logger {
    static let openWireIntent = Logger(subsystem: Bundle.main.bundleIdentifier!, category: .init(describing: OpenWireIntent.self))
}
