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
import UIKit

// MARK: - MapManagerDelegate

protocol MapViewControllerDelegate: AnyObject {

    func mapViewController(_ viewController: MapViewController, didUpdateUserLocation userLocation: MKUserLocation)
    func mapViewController(_ viewController: MapViewController, regionDidChangeAnimated animated: Bool)
    func mapViewControllerDidFinishRenderingMap(_ viewController: MapViewController, fullyRendered: Bool)

}

// MARK: - MapViewController

final class MapViewController: UIViewController {

    // MARK: - Properties

    let mapView = MKMapView()
    weak var delegate: MapViewControllerDelegate?

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)
        mapView.frame = view.bounds
        mapView.delegate = self
        configureMapView()
    }

    // MARK: - Methods

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

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        delegate?.mapViewController(self, didUpdateUserLocation: userLocation)
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        delegate?.mapViewController(self, regionDidChangeAnimated: animated)
    }

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        delegate?.mapViewControllerDidFinishRenderingMap(self, fullyRendered: fullyRendered)
    }
}
