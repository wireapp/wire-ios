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

import CoreLocation

// MARK: - AppLocationManagerDelegate

protocol AppLocationManagerDelegate: AnyObject {
    func didUpdateLocations(_ locations: [CLLocation])
    func didFailWithError(_ error: Error)
    func didChangeAuthorization(status: CLAuthorizationStatus)
}

class AppLocationManager: NSObject {

    // MARK: - Properties

    static let shared = AppLocationManager()

    private let locationManager = CLLocationManager()
    weak var delegate: AppLocationManagerDelegate?

    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }

    // MARK: - Init

    override private init() {
        super.init()
        locationManager.delegate = self
    }

    // MARK: - Methods

    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension AppLocationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.didUpdateLocations(locations)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.didFailWithError(error)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        delegate?.didChangeAuthorization(status: status)
    }

}
