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
@testable import WireDataModel

actor MockActorOneOnOneMigrator: OneOnOneMigratorInterface {
    // MARK: Lifecycle

    init() {}

    // MARK: Public

    @discardableResult
    public func migrateToMLS(userID: QualifiedID, in context: NSManagedObjectContext) async throws -> MLSGroupID {
        migrateToMLSUserIDIn_Invocations.append((userID: userID, context: context))

        if let error = migrateToMLSUserIDIn_MockError {
            throw error
        }

        if let mock = migrateToMLSUserIDIn_MockMethod {
            return try await mock(userID, context)
        } else if let mock = migrateToMLSUserIDIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `migrateToMLSUserIDIn`")
        }
    }

    // MARK: Internal

    var migrateToMLSUserIDIn_Invocations: [(userID: QualifiedID, context: NSManagedObjectContext)] = []
    var migrateToMLSUserIDIn_MockError: Error?
    var migrateToMLSUserIDIn_MockMethod: ((QualifiedID, NSManagedObjectContext) async throws -> MLSGroupID)?
    var migrateToMLSUserIDIn_MockValue: MLSGroupID?

    func setMigrateToMLSUserIDIn_MockError(_ error: Error?) {
        migrateToMLSUserIDIn_MockError = error
    }

    func setMigrateToMLSUserIDIn_MockMethod(_ method: (
        (QualifiedID, NSManagedObjectContext) async throws
            -> MLSGroupID
    )?) {
        migrateToMLSUserIDIn_MockMethod = method
    }

    func setMigrateToMLSUserIDIn_MockValue(_ value: MLSGroupID?) {
        migrateToMLSUserIDIn_MockValue = value
    }
}
