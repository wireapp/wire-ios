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

import Foundation

// MARK: - LocationSelectionViewModel

final class LocationSelectionViewModel {

    // MARK: - Nested Types

    enum AuthorizationStatus {
        case notDetermined
        case restricted
        case denied
        case authorizedAlways
        case authorizedWhenInUse
        case unknown
    }

    enum Action {
        case mapDidUpdateUserLocation
        case appLocationDidUpdate
        case mapRegionDidChange
        case mapDidFinishRendering
        case authorizationDidChange(AuthorizationStatus)
    }

    enum Effect: Equatable {
        case zoomToUserLocation
        case setInitialRegionToUserLocation
        case updateSelectedLocationPayload
        case reverseGeocodeSelectedLocation
        case requestLocationAuthorization
        case presentUnauthorizedAlert
        case startUpdatingLocation
        case showUserLocation
    }

    // MARK: - Properties

    private var hasShownInitialUserLocation = false
    private var mapDidRender = false

    // MARK: - Actions

    @discardableResult
    func perform(_ action: Action) -> [Effect] {
        switch action {
        case .mapDidUpdateUserLocation:
            guard shouldShowInitialUserLocation() else { return [] }
            return [.zoomToUserLocation]

        case .appLocationDidUpdate:
            guard shouldShowInitialUserLocation() else { return [] }
            return [.setInitialRegionToUserLocation]

        case .mapRegionDidChange:
            return selectedLocationUpdateEffects()

        case .mapDidFinishRendering:
            mapDidRender = true
            return selectedLocationUpdateEffects()

        case let .authorizationDidChange(status):
            return effects(for: status)
        }
    }

    // MARK: - Helpers

    private func shouldShowInitialUserLocation() -> Bool {
        guard !hasShownInitialUserLocation else { return false }
        hasShownInitialUserLocation = true
        return true
    }

    private func selectedLocationUpdateEffects() -> [Effect] {
        guard mapDidRender else { return [] }
        return [
            .updateSelectedLocationPayload,
            .reverseGeocodeSelectedLocation
        ]
    }

    private func effects(for status: AuthorizationStatus) -> [Effect] {
        switch status {
        case .notDetermined:
            return [.requestLocationAuthorization]
        case .restricted, .denied:
            return [.presentUnauthorizedAlert]
        case .authorizedAlways, .authorizedWhenInUse:
            return [
                .startUpdatingLocation,
                .showUserLocation
            ]
        case .unknown:
            return []
        }
    }

}
