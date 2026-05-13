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

final class MapViewModelTests: XCTestCase {

    func testInitialDisplayState() {
        let sut = MapViewModel()

        XCTAssertEqual(sut.displayState.annotations, [])
        XCTAssertNil(sut.displayState.camera)
        XCTAssertFalse(sut.displayState.isLoading)
        XCTAssertNil(sut.displayState.emptyMessage)
    }

    func testZoomToUserLocationProducesCameraEffect() {
        let sut = MapViewModel()
        let coordinate = MapViewModel.Coordinate(latitude: 52.2297, longitude: 21.0122)
        let expectedCamera = MapViewModel.CameraIntent(
            coordinate: coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500,
            animated: true
        )

        XCTAssertEqual(
            sut.perform(.zoomToUserLocation(coordinate, animated: true)),
            [.setCamera(expectedCamera)]
        )
        XCTAssertEqual(sut.displayState.camera, expectedCamera)
    }

    func testZoomToMissingUserLocationDoesNotChangeState() {
        let sut = MapViewModel()

        XCTAssertEqual(sut.perform(.zoomToUserLocation(nil, animated: true)), [])
        XCTAssertNil(sut.displayState.camera)
    }

    func testUpdateAnnotationReplacesAnnotationsAndCreatesOpenRoute() {
        let sut = MapViewModel()
        let coordinate = MapViewModel.Coordinate(latitude: 37.7749, longitude: -122.4194)
        let expectedAnnotation = MapViewModel.AnnotationIntent(coordinate: coordinate)

        XCTAssertEqual(
            sut.perform(.updateAnnotation(coordinate)),
            [.replaceAnnotations([expectedAnnotation])]
        )
        XCTAssertEqual(sut.displayState.annotations, [expectedAnnotation])
        XCTAssertEqual(sut.route(for: .openSelectedLocation), .openLocation(coordinate))
    }

    func testSetRegionStoresRequestedCameraIntent() {
        let sut = MapViewModel()
        let coordinate = MapViewModel.Coordinate(latitude: 48.8566, longitude: 2.3522)
        let expectedCamera = MapViewModel.CameraIntent(
            coordinate: coordinate,
            latitudinalMeters: 50,
            longitudinalMeters: 75,
            animated: false
        )

        XCTAssertEqual(
            sut.perform(.setRegion(
                coordinate,
                latitudinalMeters: 50,
                longitudinalMeters: 75,
                animated: false
            )),
            [.setCamera(expectedCamera)]
        )
        XCTAssertEqual(sut.displayState.camera, expectedCamera)
    }
}
