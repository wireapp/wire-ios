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

    var migrateToMLSUserIDMlsGroupID_Invocations: [(userID: QualifiedID, mlsGroupID: MLSGroupID)] = []
    var migrateToMLSUserIDMlsGroupID_MockError: Error?
    var migrateToMLSUserIDMlsGroupID_MockMethod: ((QualifiedID, MLSGroupID) async throws -> Void)?

    func setMigrateToMLSUserIDIn_MockError(_ error: Error?) {
        migrateToMLSUserIDMlsGroupID_MockError = error
    }

    func setMigrateToMLSUserIDIn_MockMethod(_ method: ((QualifiedID, MLSGroupID) async throws -> Void)?) {
        migrateToMLSUserIDMlsGroupID_MockMethod = method
    }

    public func migrateToMLS(userID: QualifiedID, mlsGroupID: MLSGroupID) async throws {
        migrateToMLSUserIDMlsGroupID_Invocations.append((userID: userID, mlsGroupID: mlsGroupID))

        if let error = migrateToMLSUserIDMlsGroupID_MockError {
            throw error
        }

        guard let mock = migrateToMLSUserIDMlsGroupID_MockMethod else {
            fatalError("no mock for `migrateToMLSUserIDMlsGroupID`")
        }

        try await mock(userID, mlsGroupID)
    }

}
