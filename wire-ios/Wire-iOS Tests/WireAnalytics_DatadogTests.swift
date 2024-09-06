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

@testable import WireCommonComponents
import XCTest

class WireAnalytics_DatadogTests: XCTestCase {

    func test_enable_isExecutedOnlyOnce() {
        // GIVEN
        var count = 0
        WireAnalytics.Datadog.enableOnlyOnce = .init({
            count += 1
        })
        let concurrentQueue = DispatchQueue(label: "test", attributes: .concurrent)

        // WHEN
        for i in 1...1000 {
            concurrentQueue.async {
                WireAnalytics.Datadog.enable()
            }
        }

        // THEN
        XCTAssertEqual(count, 1)
    }
}
