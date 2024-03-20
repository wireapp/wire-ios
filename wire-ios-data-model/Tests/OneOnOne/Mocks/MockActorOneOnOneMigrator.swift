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

    // MARK: - Life cycle

    init() {}

    // MARK: - migrateToMLS

    var migrateToMLSUserIDMlsGroupIDIn_Invocations: [(userID: QualifiedID, mlsGroupID: MLSGroupID, context: NSManagedObjectContext)] = []
    var migrateToMLSUserIDMlsGroupIDIn_MockError: Error?
    var migrateToMLSUserIDMlsGroupIDIn_MockMethod: ((QualifiedID, MLSGroupID, NSManagedObjectContext) async throws -> Void)?

    func setMigrateToMLSUserIDMlsGroupIDIn_MockError(_ error: Error?) {
        migrateToMLSUserIDMlsGroupIDIn_MockError = error
    }

    func setMigrateToMLSUserIDIn_MockMethod(_ method: ((QualifiedID, MLSGroupID, NSManagedObjectContext) async throws -> Void)?) {
        migrateToMLSUserIDMlsGroupIDIn_MockMethod = method
    }

    func migrateToMLS(userID: QualifiedID, mlsGroupID: MLSGroupID, in context: NSManagedObjectContext) async throws {
        migrateToMLSUserIDMlsGroupIDIn_Invocations.append((userID: userID, mlsGroupID: mlsGroupID, context: context))

        if let error = migrateToMLSUserIDMlsGroupIDIn_MockError {
            throw error
        }

        guard let mock = migrateToMLSUserIDMlsGroupIDIn_MockMethod else {
            fatalError("no mock for `migrateToMLSUserIDMlsGroupIDIn`")
        }

        try await mock(userID, mlsGroupID, context)
    }
}
