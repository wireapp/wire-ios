//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

extension XCTestCase {
    func verifyDeallocation<T: AnyObject>(of instanceGenerator: () -> (T)) {
        weak var weakInstance: T?
        var instance: T?

        autoreleasepool {
            instance = instanceGenerator()
            // then
            weakInstance = instance
            XCTAssertNotNil(weakInstance)
            // when
            instance = nil
        }

        XCTAssertNil(instance)
        XCTAssertNil(weakInstance)
    }
}

public extension XCTestCase {

    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance should have been deallocated. Potential memory leak.",
                file: file,
                line: line
            )
        }
    }
}
