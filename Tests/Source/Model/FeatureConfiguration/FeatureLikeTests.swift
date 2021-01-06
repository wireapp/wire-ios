//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import XCTest
@testable import WireDataModel

class FeatureLikeTests: ZMBaseManagedObjectTest {

    func testThatItStoresAFeatureLikeObject() throws {
        // Given
        let appLock = Feature.AppLock(status: .enabled, config: .init(enforceAppLock: true, inactivityTimeoutSecs: 10))

        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()

        // When
        try appLock.store(for: team, in: uiMOC)

        // Then
        guard let result = Feature.fetch(name: .appLock, context: uiMOC) else { return XCTFail() }
        XCTAssertEqual(result.name, .appLock)
        XCTAssertEqual(result.status, .enabled)
        XCTAssertEqual(result.config, appLock.configData)
        XCTAssertEqual(result.team?.remoteIdentifier, team.remoteIdentifier!)

    }
}

private extension Feature.AppLock {

    var configData: Data {
        return try! JSONEncoder().encode(config)
    }

}
