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
    }

    override func tearDown() {
        mockServerConnection = nil

        super.tearDown()
    }

    func testQualityType_givenNoConnection_thenIsUnknown() throws {
        // given
        mockServerConnection.isOffline = true
        mockServerConnection.isMobileConnection = false

        let networkInfo = makeNetworkInfo()

        // when & then
        XCTAssertEqual(networkInfo.qualityType(), .unknown)
    }

    func testQualityType_givenConnectionAndIsMobileWithoutTechnology_thenIsUnknown() throws {
        // given
        mockServerConnection.isOffline = false
        mockServerConnection.isMobileConnection = true

        let networkInfo = makeNetworkInfo()

        // when & then
        XCTAssertEqual(networkInfo.qualityType(), .unknown)
    }

    func testQualityType_givenConnectionAndIsNotMobile_thenIsWifi() throws {
        // given
        mockServerConnection.isOffline = false
        mockServerConnection.isMobileConnection = false

        let networkInfo = makeNetworkInfo()

        // when & then
        XCTAssertEqual(networkInfo.qualityType(), .typeWifi)
    }

    func testfindBestQualityType_givenNoMobileConnection_thenIsUnknown() {
        // given
        let networkInfo = makeNetworkInfo()
        let radioAccessTechnology = [String: String]()

        // when & then
        let qualityType = networkInfo.findBestQualityType(of: radioAccessTechnology)
        XCTAssertEqual(qualityType, .unknown)
    }

    func testfindBestQualityType_givenMobileConnectionEdge_thenIsType2G() {
        // given
        let networkInfo = makeNetworkInfo()
        let radioAccessTechnology = [
            "0": CTRadioAccessTechnologyEdge
        ]

        // when & then
        let qualityType = networkInfo.findBestQualityType(of: radioAccessTechnology)
        XCTAssertEqual(qualityType, .type2G)
    }

    func testfindBestQualityType_givenMobileConnectionLTE_thenIsType3G() {
        // given
        let networkInfo = makeNetworkInfo()
        let radioAccessTechnology = [
            "0": CTRadioAccessTechnologyEdge,
            "1": CTRadioAccessTechnologyLTE
        ]

        // when & then
        let qualityType = networkInfo.findBestQualityType(of: radioAccessTechnology)
        XCTAssertEqual(qualityType, .type4G)
    }

    func testfindBestQualityType_givenMobileConnectionHSDPA_thenIsType4G() {
        // given
        let networkInfo = makeNetworkInfo()
        let radioAccessTechnology = [
            "0": CTRadioAccessTechnologyEdge,
            "1": CTRadioAccessTechnologyLTE,
            "2": CTRadioAccessTechnologyHSDPA
        ]

        // when & then
        let qualityType = networkInfo.findBestQualityType(of: radioAccessTechnology)
        XCTAssertEqual(qualityType, .type4G)
    }

    // MARK: Helpers

    private func makeNetworkInfo() -> NetworkInfo {
        NetworkInfo(serverConnection: mockServerConnection)
    }
}
