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
@testable import Wire

final class LocationSendViewModelTests: XCTestCase {

    func testDisplayStateBeforeLocationIsSelected() {
        let sut = LocationSendViewModel()

        XCTAssertFalse(sut.displayState.canSend)
        XCTAssertNil(sut.displayState.selectedLocationPayload)
    }

    func testDisplayStateAfterLocationIsSelected() {
        let sut = LocationSendViewModel()

        sut.perform(.updateSelectedAddress("Hackescher Markt"))
        sut.perform(.updateSelectedLocation(latitude: 52.522, longitude: 13.402, zoomLevel: 16))

        let payload = sut.displayState.selectedLocationPayload
        XCTAssertTrue(sut.displayState.canSend)
        XCTAssertEqual(payload?.latitude, 52.522)
        XCTAssertEqual(payload?.longitude, 13.402)
        XCTAssertEqual(payload?.address, "Hackescher Markt")
        XCTAssertEqual(payload?.zoomLevel, 16)
    }

    func testUpdatingAddressReturnsHeightRoute() {
        let sut = LocationSendViewModel()

        let routes = sut.perform(.updateSelectedAddress("Hackescher Markt"))

        guard case let .updateHeight(shouldUseCompactHeight)? = routes.first else {
            return XCTFail("Expected update height route")
        }

        XCTAssertFalse(shouldUseCompactHeight)
    }

    func testSendButtonTappedReturnsSendRouteWhenLocationIsSelected() {
        let sut = LocationSendViewModel()
        sut.perform(.updateSelectedAddress("Hackescher Markt"))
        sut.perform(.updateSelectedLocation(latitude: 52.522, longitude: 13.402, zoomLevel: 16))

        let routes = sut.perform(.sendButtonTapped)

        guard case let .send(locationData)? = routes.first else {
            return XCTFail("Expected send route")
        }

        XCTAssertEqual(locationData.latitude, 52.522)
        XCTAssertEqual(locationData.longitude, 13.402)
        XCTAssertEqual(locationData.name, "Hackescher Markt")
        XCTAssertEqual(locationData.zoomLevel, 16)
    }

}
