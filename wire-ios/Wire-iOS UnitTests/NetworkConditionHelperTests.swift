// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
@testable import Wire
import CoreTelephony

final class NetworkConditionHelperTests: XCTestCase {

    var sut: NetworkConditionHelper!

    override func setUp() {
        super.setUp()
        sut = NetworkConditionHelper()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatSharedInstanceReturnQualityTypeWifi() {
        SessionManager.shared?.markNetworkSessionsAsReady(true)
        XCTAssertEqual(NetworkConditionHelper.shared.qualityType(), .typeWifi)
    }

    func testThatBestQualityTypeIsChosen() {
        // GIVEN
        let mockServiceCurrentRadioAccessTechnology = ["0": CTRadioAccessTechnologyEdge,
                                                       "1": CTRadioAccessTechnologyLTE,
                                                       "2": CTRadioAccessTechnologyHSDPA]

        // WHEN & THEN
        XCTAssertEqual(sut.bestQualityType(cellularTypeDict: mockServiceCurrentRadioAccessTechnology), .type4G)
    }
}
