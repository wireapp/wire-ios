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

final class NetworkInfoTests: XCTestCase {

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
        // given
        let networkInfo = makeNetworkInfo()

        // when & then
        XCTAssertEqual(networkInfo.qualityType(), .typeWifi)
    }

    func testThatBestQualityTypeIsChosen() {
        // given
        let networkInfo = makeNetworkInfo()
        let mockServiceCurrentRadioAccessTechnology = [
            "0": CTRadioAccessTechnologyEdge,
            "1": CTRadioAccessTechnologyLTE,
            "2": CTRadioAccessTechnologyHSDPA
        ]

        // when & then
        let qualityType = networkInfo.qualityType()
        XCTAssertEqual(qualityType, .type4G)
    }

    // MARK: Helpers

    private func makeNetworkInfo() -> NetworkInfo {
        NetworkInfo(serverConnection: mockServerConnection)
    }
}
