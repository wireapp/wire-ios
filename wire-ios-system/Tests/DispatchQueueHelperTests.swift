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

import WireSystem
import XCTest

final class DispatchQueueHelperTests: XCTestCase {

    func testThatItEntersAndLeavesADispatchGroup() async {
        // Given
        let group = ZMSDispatchGroup(label: name)
        let queue = DispatchQueue(label: name)
        let groupExpectation = expectation(description: "It should leave the group")

        final class Counter: @unchecked Sendable { var value = 0 }
        let counter = Counter()

        // When
        queue.async(group: group) {
            counter.value = 42
        }

        // Then
        group.notify(on: .main) {
            XCTAssertEqual(counter.value, 42)
            groupExpectation.fulfill()
        }

        await fulfillment(of: [groupExpectation], timeout: 0.1)
    }
}
