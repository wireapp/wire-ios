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

// TODO: [WPB-8907] use the type `WeakReference` from WireSystem once WireSystem has become a Swift package.
extension XCTestCase {

    public func wait(
        forConditionToBeTrue predicate: @escaping @autoclosure () -> Bool,
        timeout seconds: TimeInterval
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: .init { _, _ in predicate() },
            object: .none
        )
        wait(for: [expectation], timeout: seconds)
    }
}
