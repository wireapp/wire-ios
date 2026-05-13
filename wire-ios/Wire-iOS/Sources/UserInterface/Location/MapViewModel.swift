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

import CoreLocation
import Foundation

// MARK: - MapViewModel

final class MapViewModel {

    // MARK: - Nested Types

    struct Coordinate: Equatable {
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees

        init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
            self.latitude = latitude
            self.longitude = longitude
        }

        init(_ coordinate: CLLocationCoordinate2D) {
            self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }

        var locationCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    struct AnnotationIntent: Equatable {
        let coordinate: Coordinate
    }

    struct CameraIntent: Equatable {
        let coordinate: Coordinate
        let latitudinalMeters: CLLocationDistance
        let longitudinalMeters: CLLocationDistance
        let animated: Bool
    }

    struct DisplayState: Equatable {
        let annotations: [AnnotationIntent]
        let camera: CameraIntent?
        let isLoading: Bool
        let emptyMessage: String?
    }

    enum Action {
        case zoomToUserLocation(Coordinate?, animated: Bool)
        case updateAnnotation(Coordinate)
        case setRegion(
            Coordinate,
            latitudinalMeters: CLLocationDistance,
            longitudinalMeters: CLLocationDistance,
            animated: Bool
        )
        case openSelectedLocation
    }

    enum Effect: Equatable {
        case setCamera(CameraIntent)
        case replaceAnnotations([AnnotationIntent])
    }

    enum Route: Equatable {
        case openLocation(Coordinate)
    }

    // MARK: - Properties

    private(set) var displayState = DisplayState(
        annotations: [],
        camera: nil,
        isLoading: false,
        emptyMessage: nil
    )

    // MARK: - Actions

    @discardableResult
    func perform(_ action: Action) -> [Effect] {
        switch action {
        case let .zoomToUserLocation(coordinate, animated):
            guard let coordinate else { return [] }

            let camera = CameraIntent(
                coordinate: coordinate,
                latitudinalMeters: 500,
                longitudinalMeters: 500,
                animated: animated
            )
            displayState = displayState.updating(camera: camera)
            return [.setCamera(camera)]

        case let .updateAnnotation(coordinate):
            let annotation = AnnotationIntent(coordinate: coordinate)
            displayState = displayState.updating(annotations: [annotation])
            return [.replaceAnnotations([annotation])]

        case let .setRegion(coordinate, latitudinalMeters, longitudinalMeters, animated):
            let camera = CameraIntent(
                coordinate: coordinate,
                latitudinalMeters: latitudinalMeters,
                longitudinalMeters: longitudinalMeters,
                animated: animated
            )
            displayState = displayState.updating(camera: camera)
            return [.setCamera(camera)]

        case .openSelectedLocation:
            return []
        }
    }

    func route(for action: Action) -> Route? {
        switch action {
        case .openSelectedLocation:
            return displayState.annotations.first.map { .openLocation($0.coordinate) }
        case .zoomToUserLocation, .updateAnnotation, .setRegion:
            return nil
        }
    }

}

private extension MapViewModel.DisplayState {

    func updating(
        annotations: [MapViewModel.AnnotationIntent]? = nil,
        camera: MapViewModel.CameraIntent? = nil
    ) -> Self {
        Self(
            annotations: annotations ?? self.annotations,
            camera: camera ?? self.camera,
            isLoading: isLoading,
            emptyMessage: emptyMessage
        )
    }

}
