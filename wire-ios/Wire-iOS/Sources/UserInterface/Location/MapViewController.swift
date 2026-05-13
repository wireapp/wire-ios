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

import MapKit
import UIKit

// MARK: - MapViewControllerDelegate

protocol MapViewControllerDelegate: AnyObject {

    func mapViewController(_ controller: MapViewController, didUpdateUserLocation userLocation: MKUserLocation)
    func mapViewController(_ controller: MapViewController, regionDidChangeAnimated animated: Bool)
    func mapViewControllerDidFinishRenderingMap(_ controller: MapViewController, fullyRendered: Bool)

}

// MARK: - MapViewController

/// The MapViewController class is a subclass of UIViewController that manages a map interface using MKMapView.
/// This class is designed to handle map-related functionalities such as displaying the user’s location, adding and
/// updating annotations, and adjusting the map’s region.
final class MapViewController: UIViewController {

    // MARK: - Properties

    let mapView = MKMapView()
    weak var delegate: MapViewControllerDelegate?
    private let viewModel = MapViewModel()
    private let pointAnnotation = MKPointAnnotation()
    private lazy var annotationView: MKMarkerAnnotationView = .init(
        annotation: pointAnnotation,
        reuseIdentifier: String(
            describing: type(of: self)
        )
    )

    enum LayoutConstants {
        static let annotationViewCenterXOffset: CGFloat = 8.5
        static let annotationViewBottomOffset: CGFloat = 5
        static let annotationViewHeight: CGFloat = 39
        static let annotationViewWidth: CGFloat = 32
    }

    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)
        mapView.frame = view.bounds
        mapView.delegate = self
        configureMapView()
        setupAnnotationView()
    }

    // MARK: - Methods

    private func configureMapView() {
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupAnnotationView() {
        pointAnnotation.coordinate = mapView.centerCoordinate
        mapView.addSubview(annotationView)
        annotationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            annotationView.centerXAnchor.constraint(
                equalTo: mapView.centerXAnchor,
                constant: LayoutConstants.annotationViewCenterXOffset
            ),
            annotationView.bottomAnchor.constraint(
                equalTo: mapView.centerYAnchor,
                constant: LayoutConstants.annotationViewBottomOffset
            ),
            annotationView.heightAnchor.constraint(equalToConstant: LayoutConstants.annotationViewHeight),
            annotationView.widthAnchor.constraint(equalToConstant: LayoutConstants.annotationViewWidth)
        ])
    }

    func zoomToUserLocation(animated: Bool) {
        guard let coordinate = mapView.userLocation.location?.coordinate else { return }
        handle(viewModel.perform(.zoomToUserLocation(.init(coordinate), animated: animated)))
    }

    func updateAnnotation(to coordinate: CLLocationCoordinate2D) {
        handle(viewModel.perform(.updateAnnotation(.init(coordinate))))
    }

    func setRegion(
        to coordinate: CLLocationCoordinate2D,
        latitudinalMeters: Double,
        longitudinalMeters: Double,
        animated: Bool
    ) {
        handle(viewModel.perform(.setRegion(
            .init(coordinate),
            latitudinalMeters: latitudinalMeters,
            longitudinalMeters: longitudinalMeters,
            animated: animated
        )))
    }

    private func handle(_ effects: [MapViewModel.Effect]) {
        for effect in effects {
            switch effect {
            case let .setCamera(camera):
                setCamera(camera)
            case let .replaceAnnotations(annotations):
                replaceAnnotations(annotations)
            }
        }
    }

    private func setCamera(_ camera: MapViewModel.CameraIntent) {
        let region = MKCoordinateRegion(
            center: camera.coordinate.locationCoordinate,
            latitudinalMeters: camera.latitudinalMeters,
            longitudinalMeters: camera.longitudinalMeters
        )
        mapView.setRegion(region, animated: camera.animated)
    }

    private func replaceAnnotations(_ annotations: [MapViewModel.AnnotationIntent]) {
        mapView.removeAnnotations(mapView.annotations)

        let mapAnnotations = annotations.map { annotationIntent in
            let annotation = MKPointAnnotation()
            annotation.coordinate = annotationIntent.coordinate.locationCoordinate
            return annotation
        }
        mapView.addAnnotations(mapAnnotations)
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
