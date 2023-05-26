//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import XCTest
@testable import WireDataModel

class StaleMLSKeyDetectorTests: ZMBaseManagedObjectTest {

    func test_GroupsWithStaleKeyingMaterial() throws {
        syncMOC.performGroupedAndWait { context in
            // Given
            let sut = StaleMLSKeyDetector(
                refreshIntervalInDays: 5,
                context: context
            )

            let staleGroup1 = self.createMLSGroup(in: context)
            staleGroup1.lastKeyMaterialUpdate = .distantPast

            let staleGroup2 = self.createMLSGroup(in: context)
            staleGroup2.lastKeyMaterialUpdate = Date().addingTimeInterval(.oneDay * -6)

            let nonStaleGroup = self.createMLSGroup(in: context)
            nonStaleGroup.lastKeyMaterialUpdate = Date().addingTimeInterval(.oneDay * -2)

            // When
            let result = sut.groupsWithStaleKeyingMaterial

            // Then
            XCTAssertTrue(result.contains(staleGroup1.id))
            XCTAssertTrue(result.contains(staleGroup2.id))
            XCTAssertFalse(result.contains(nonStaleGroup.id))
        }

    }

    func test_KeyingMaterialUpdated() throws {
        try syncMOC.performGroupedAndWait { context in
            // Given
            let sut = StaleMLSKeyDetector(
                refreshIntervalInDays: 5,
                context: context
            )

            let group = self.createMLSGroup(in: context)
            XCTAssertNil(group.lastKeyMaterialUpdate)

            // When
            sut.keyingMaterialUpdated(for: group.id)

            // Then
            let lastUpdate = try XCTUnwrap(group.lastKeyMaterialUpdate)

            XCTAssertEqual(
                lastUpdate.timeIntervalSinceNow,
                Date().timeIntervalSinceNow,
                accuracy: 0.1
            )
        }
    }

}
