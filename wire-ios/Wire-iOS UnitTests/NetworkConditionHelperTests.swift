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
import CoreTelephony
import WireSyncEngineSupport

@testable import Wire

final class NetworkConditionHelperTests: XCTestCase {

    private var mockServerConnection: MockServerConnection!

    override func setUp() {
        super.setUp()

        mockServerConnection = MockServerConnection()
        mockServerConnection.isOffline = true
        mockServerConnection.isMobileConnection = false
    }

    override func tearDown() {
        mockServerConnection = nil

        super.tearDown()
    }

    // NOTE: this test can fail if your local network conditions are bad/offline?!
    func testThatSharedInstanceReturnQualityTypeWifi() throws {
        let helper = makeNetworkConditionHelper()
        XCTAssertEqual(helper.qualityType(), .typeWifi)
    }

    func testThatBestQualityTypeIsChosen() {
        // GIVEN
        let helper = makeNetworkConditionHelper()
        let mockServiceCurrentRadioAccessTechnology = [
            "0": CTRadioAccessTechnologyEdge,
            "1": CTRadioAccessTechnologyLTE,
            "2": CTRadioAccessTechnologyHSDPA
        ]

        // WHEN & THEN
        let qualityType = helper.qualityType()
        XCTAssertEqual(qualityType, .type4G)
    }

    // MARK: Helpers

    private func makeNetworkConditionHelper() -> NetworkConditionHelper {
        NetworkConditionHelper(serverConnection: mockServerConnection)
    }
}
