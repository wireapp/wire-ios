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

import XCTest

@testable import WireDataModel

class StaleMLSKeyDetectorTests: ZMBaseManagedObjectTest {
    var sut: StaleMLSKeyDetector!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        sut = StaleMLSKeyDetector(
            refreshIntervalInDays: 5,
            context: syncMOC
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_GroupsWithStaleKeyingMaterial() throws {
        syncMOC.performGroupedAndWait {
            // Given
            let staleGroup1 = self.createMLSGroup(in: syncMOC)
            staleGroup1.lastKeyMaterialUpdate = .distantPast

            let staleGroup2 = self.createMLSGroup(in: syncMOC)
            staleGroup2.lastKeyMaterialUpdate = Date().addingTimeInterval(.oneDay * -6)

            let nonStaleGroup = self.createMLSGroup(in: syncMOC)
            nonStaleGroup.lastKeyMaterialUpdate = Date().addingTimeInterval(.oneDay * -2)

            // When
            let result = self.sut.groupsWithStaleKeyingMaterial

            // Then
            XCTAssertTrue(result.contains(staleGroup1.id))
            XCTAssertTrue(result.contains(staleGroup2.id))
            XCTAssertFalse(result.contains(nonStaleGroup.id))
        }
    }

    func test_KeyingMaterialUpdated() throws {
        var group: MLSGroup!

        syncMOC.performGroupedBlock {
            // Given
            group = self.createMLSGroup(in: self.syncMOC)
            XCTAssertNil(group.lastKeyMaterialUpdate)

            // When
            self.sut.keyingMaterialUpdated(for: group.id)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlock {
            // Then
            guard let lastUpdate = group.lastKeyMaterialUpdate else {
                XCTFail("expected lastKeyMaterialUpdate")
                return
            }

            XCTAssertEqual(
                lastUpdate.timeIntervalSinceNow,
                Date().timeIntervalSinceNow,
                accuracy: 0.15
            )
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}
