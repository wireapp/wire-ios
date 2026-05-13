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

final class LocationSelectionViewModelTests: XCTestCase {

    func testMapUserLocationUpdateZoomsOnlyOnce() {
        let sut = LocationSelectionViewModel()

        XCTAssertEqual(sut.perform(.mapDidUpdateUserLocation), [.zoomToUserLocation])
        XCTAssertEqual(sut.perform(.mapDidUpdateUserLocation), [])
    }

    func testAppLocationUpdateSetsInitialRegionOnlyOnce() {
        let sut = LocationSelectionViewModel()

        XCTAssertEqual(sut.perform(.appLocationDidUpdate), [.setInitialRegionToUserLocation])
        XCTAssertEqual(sut.perform(.appLocationDidUpdate), [])
    }

    func testMapRegionChangeDoesNotUpdateSelectionBeforeMapRendered() {
        let sut = LocationSelectionViewModel()

        XCTAssertEqual(sut.perform(.mapRegionDidChange), [])
    }

    func testMapRenderEnablesSelectionUpdates() {
        let sut = LocationSelectionViewModel()
        let expectedEffects: [LocationSelectionViewModel.Effect] = [
            .updateSelectedLocationPayload,
            .reverseGeocodeSelectedLocation
        ]

        XCTAssertEqual(sut.perform(.mapDidFinishRendering), expectedEffects)
        XCTAssertEqual(sut.perform(.mapRegionDidChange), expectedEffects)
    }

    func testAuthorizationStatusEffects() {
        let sut = LocationSelectionViewModel()

        XCTAssertEqual(sut.perform(.authorizationDidChange(.notDetermined)), [.requestLocationAuthorization])
        XCTAssertEqual(sut.perform(.authorizationDidChange(.restricted)), [.presentUnauthorizedAlert])
        XCTAssertEqual(sut.perform(.authorizationDidChange(.denied)), [.presentUnauthorizedAlert])
        XCTAssertEqual(
            sut.perform(.authorizationDidChange(.authorizedAlways)),
            [.startUpdatingLocation, .showUserLocation]
        )
        XCTAssertEqual(
            sut.perform(.authorizationDidChange(.authorizedWhenInUse)),
            [.startUpdatingLocation, .showUserLocation]
        )
        XCTAssertEqual(sut.perform(.authorizationDidChange(.unknown)), [])
    }

}
