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

protocol MapManagerDelegate: AnyObject {
    func mapManager(_ manager: MapManager, didUpdateUserLocation userLocation: MKUserLocation)
    func mapManager(_ manager: MapManager, regionDidChangeAnimated animated: Bool)
    func mapManagerDidFinishRenderingMap(_ manager: MapManager, fullyRendered: Bool)
}

class MapManager: NSObject {
    let mapView = MKMapView()
    weak var delegate: MapManagerDelegate?

    override init() {
        super.init()
        mapView.delegate = self
        configureMapView()
    }

    private func configureMapView() {
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
    }

    func zoomToUserLocation(animated: Bool) {
        guard let coordinate = mapView.userLocation.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: animated)
    }

    func updateAnnotation(to coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.removeAnnotations(mapView.annotations) // Remove existing annotations
        mapView.addAnnotation(annotation)
    }
}

extension MapManager: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        delegate?.mapManager(self, didUpdateUserLocation: userLocation)
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        delegate?.mapManager(self, regionDidChangeAnimated: animated)
    }

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        delegate?.mapManagerDidFinishRenderingMap(self, fullyRendered: fullyRendered)
    }
}
