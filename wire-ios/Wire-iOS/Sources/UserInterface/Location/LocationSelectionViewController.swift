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
import MapKit
import UIKit
import WireDataModel

protocol LocationSelectionViewControllerDelegate: AnyObject {
    func locationSelectionViewController(_ viewController: LocationSelectionViewController, didSelectLocationWithData locationData: LocationData)
    func locationSelectionViewControllerDidCancel(_ viewController: LocationSelectionViewController)
}

final class LocationSelectionViewController: UIViewController {

    // MARK: - Constants

    enum LayoutConstants {
        static let sendControllerHeight: CGFloat = 56
        static let annotationViewCenterXOffset: CGFloat = 8.5
        static let annotationViewBottomOffset: CGFloat = 5
        static let annotationViewHeight: CGFloat = 39
        static let annotationViewWidth: CGFloat = 32
        static let locationButtonLeadingOffset: CGFloat = 16
        static let locationButtonBottomOffset: CGFloat = -16
        static let locationButtonWidth: CGFloat = 28
        static let locationButtonHeight: CGFloat = 28
    }

    // MARK: - Properties

    weak var delegate: LocationSelectionViewControllerDelegate?

    let locationButton: IconButton = {
        let button = IconButton()
        button.setIcon(.location, size: .tiny, for: [])
        button.borderWidth = 0.5
        button.setBorderColor(SemanticColors.View.borderInputBar, for: .normal)

        button.circular = true
        button.backgroundColor = SemanticColors.View.backgroundDefault
        button.setIconColor(SemanticColors.Icon.foregroundDefault, for: .normal)

        return button
    }()

    let locationButtonContainer = UIView()
    var sendControllerHeightConstraint: NSLayoutConstraint?

    private var mapView = MKMapView()
    private let toolBar = ModalTopBar()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let sendViewController = LocationSendViewController()
    private let pointAnnotation = MKPointAnnotation()
    private lazy var annotationView: MKPinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: String(describing: type(of: self)))
    private var userShowedInitially = false
    private var mapDidRender = false

    private var userLocationAuthorized: Bool {
        let status = locationManager.authorizationStatus
        return status == .authorizedAlways || status == .authorizedWhenInUse
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        mapView.delegate = self
        toolBar.delegate = self
        sendViewController.delegate = self

        configureViews()
        createConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !userLocationAuthorized { mapView.restoreLocation(animated: true) }
        locationManager.requestWhenInUseAuthorization()
        updateUserLocation()

        endEditing()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingHeading()
        mapView.storeLocation()
    }

    // MARK: - Configuration

    private func configureViews() {
        addChild(sendViewController)
        sendViewController.didMove(toParent: self)
        [mapView, sendViewController.view, toolBar, locationButton].forEach(view.addSubview)

        let action = UIAction { [weak self] _ in
            self?.locationButtonTapped()
        }

        locationButton.addAction(action, for: .touchUpInside)

        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        toolBar.configure(title: title ?? "", subtitle: nil, topAnchor: safeTopAnchor)
        pointAnnotation.coordinate = mapView.centerCoordinate

        mapView.addSubview(annotationView)
    }

    private func createConstraints() {
        guard let sendController = sendViewController.view else { return }

        [mapView, sendController, annotationView, toolBar, locationButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        sendControllerHeightConstraint = sendController.heightAnchor.constraint(equalToConstant: LayoutConstants.sendControllerHeight + UIScreen.safeArea.bottom)
        sendControllerHeightConstraint?.isActive = false

        NSLayoutConstraint.activate([
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sendController.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sendController.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sendController.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toolBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBar.topAnchor.constraint(equalTo: view.topAnchor),
            toolBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            annotationView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor, constant: LayoutConstants.annotationViewCenterXOffset),
            annotationView.bottomAnchor.constraint(equalTo: mapView.centerYAnchor, constant: LayoutConstants.annotationViewBottomOffset),
            annotationView.heightAnchor.constraint(equalToConstant: LayoutConstants.annotationViewHeight),
            annotationView.widthAnchor.constraint(equalToConstant: LayoutConstants.annotationViewWidth),

            locationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: LayoutConstants.locationButtonLeadingOffset),
            locationButton.bottomAnchor.constraint(equalTo: sendController.topAnchor, constant: LayoutConstants.locationButtonBottomOffset),
            locationButton.widthAnchor.constraint(equalToConstant: LayoutConstants.locationButtonWidth),
            locationButton.heightAnchor.constraint(equalToConstant: LayoutConstants.locationButtonHeight)
        ])
    }

    // MARK: - User Actions

    private func locationButtonTapped() {
        zoomToUserLocation(true)
    }

    // MARK: - Helpers

    private func updateUserLocation() {
        mapView.showsUserLocation = userLocationAuthorized
        if userLocationAuthorized {
            locationManager.startUpdatingLocation()
        }
    }

    private func zoomToUserLocation(_ animated: Bool) {
        guard userLocationAuthorized else { return presentUnauthorizedAlert() }
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 50, longitudinalMeters: 50)
        mapView.setRegion(region, animated: animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    private func presentUnauthorizedAlert() {
        let alertController = UIAlertController(
            title: L10n.Localizable.Location.UnauthorizedAlert.title,
            message: L10n.Localizable.Location.UnauthorizedAlert.message,
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(
            title: L10n.Localizable.Location.UnauthorizedAlert.cancel,
            style: .cancel,
            handler: nil
        )

        let settingsAction = UIAlertAction(
            title: L10n.Localizable.Location.UnauthorizedAlert.settings,
            style: .default
        ) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }

        [cancelAction, settingsAction].forEach(alertController.addAction)
        present(alertController, animated: true, completion: nil)
    }

    private func formatAndUpdateAddress() {
        guard mapDidRender else { return }
        geocoder.reverseGeocodeLocation(mapView.centerCoordinate.location) { [weak self] placemarks, error in
            guard error == nil, let placemark = placemarks?.first else { return }
            if let address = placemark.formattedAddress(false), !address.isEmpty {
                self?.sendViewController.address = address
            } else {
                self?.sendViewController.address = nil
            }
        }
    }
}

// MARK: - Location Manager Delegate

extension LocationSelectionViewController: LocationSendViewControllerDelegate {

    func locationSendViewController(_ viewController: LocationSendViewController, shouldChangeHeight isActive: Bool) {

        sendControllerHeightConstraint?.isActive = isActive

        if isActive {
            sendControllerHeightConstraint?.constant = 56 + UIScreen.safeArea.bottom
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    func locationSendViewControllerSendButtonTapped(_ viewController: LocationSendViewController) {
        let locationData = mapView.locationData(name: viewController.address)
        delegate?.locationSelectionViewController(self, didSelectLocationWithData: locationData)
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Map View Delegate

extension LocationSelectionViewController: ModalTopBarDelegate {

    func modelTopBarWantsToBeDismissed(_ topBar: ModalTopBar) {
        delegate?.locationSelectionViewControllerDidCancel(self)
    }

}

// MARK: - Location Send View Controller Delegate

extension LocationSelectionViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        updateUserLocation()
    }

}

// MARK: - Modal Top Bar Delegate

extension LocationSelectionViewController: MKMapViewDelegate {

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        mapDidRender = true
        formatAndUpdateAddress()
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        formatAndUpdateAddress()
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !userShowedInitially {
            userShowedInitially = true
            zoomToUserLocation(true)
        }
    }

}
