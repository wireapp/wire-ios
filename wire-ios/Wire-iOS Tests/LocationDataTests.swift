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

import MapKit
@testable import Wire
import WireDataModel
import XCTest

final class LocationDataTests: XCTestCase {

    override func tearDown() {
        Settings.shared.reset()
        super.tearDown()
    }

    func testThatLocationDataCanBeStored() {
        // given
        let location: LocationData = LocationData.locationData(withLatitude: 1, longitude: 2, name: "test", zoomLevel: 3)
        Settings.shared[.lastUserLocation] = location

        // when
        let sut: LocationData? = Settings.shared[.lastUserLocation]

        // then
        XCTAssertEqual(sut?.latitude, 1)
        XCTAssertEqual(sut?.longitude, 2)
        XCTAssertEqual(sut?.zoomLevel, 3)
    }

    func testThatLocationDataCanBeConvertedToADictionary() {
        // given
        let sut = LocationData.locationData(
            withLatitude: 45,
            longitude: 75,
            name: name,
            zoomLevel: 5
        )

        // when
        let dict = sut.toDictionary()

        // then
        XCTAssertEqual(dict["LastLocationLatitudeKey"] as? Float, Float(45))
        XCTAssertEqual(dict["LastLocationLongitudeKey"] as? Float, Float(75))
        XCTAssertEqual(dict["LastLocationZoomLevelKey"] as? Int, 5)
    }

    func testThatLocationDataCanBeCreatedFromADictionary() {
        // when
        let sut = LocationData.locationData(fromDictionary: [
            "LastLocationLatitudeKey": 45.0,
            "LastLocationLongitudeKey": 75.0,
            "LastLocationZoomLevelKey": 5
        ])

        // then
        XCTAssertEqual(sut?.latitude, 45)
        XCTAssertEqual(sut?.longitude, 75)
        XCTAssertEqual(sut?.zoomLevel, 5)
        XCTAssertNil(sut?.name)
    }

}
