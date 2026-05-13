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
import MapKit
import UIKit
import WireDataModel
import WireDesign

protocol LocationSelectionViewControllerDelegate: AnyObject {
    func locationSelectionViewController(
        _ viewController: LocationSelectionViewController,
        didSelectLocationWithData locationData: LocationData
    )
    func locationSelectionViewControllerDidCancel(_ viewController: LocationSelectionViewController)
}

final class LocationSelectionViewController: UIViewController {

    // MARK: - Constants

    enum LayoutConstants {
        static let sendControllerHeight: CGFloat = 56
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

    var sendControllerHeightConstraint: NSLayoutConstraint?

    private let mapViewController = MapViewController()
    private let geocoder = CLGeocoder()
    private let sendViewController = LocationSendViewController()
    private let viewModel = LocationSelectionViewModel()

    lazy var appLocationManager: AppLocationManagerProtocol = {
        let manager = AppLocationManager()
        manager.delegate = self
        return manager
    }()

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        mapViewController.delegate = self
        sendViewController.delegate = self

        configureViews()
        createConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupNavigationBarTitle(title ?? "")
        navigationController?.navigationBar.backgroundColor = SemanticColors.View.backgroundDefault

        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: L10n.Localizable.General.close)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !appLocationManager.userLocationAuthorized {
            mapViewController.mapView.restoreLocation(animated: animated)
        }
        appLocationManager.requestLocationAuthorization()
        view.window?.endEditing(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appLocationManager.stopUpdatingLocation()
        mapViewController.mapView.storeLocation()
    }

    // MARK: - Configuration

    private func configureViews() {
        addChild(mapViewController)
        mapViewController.didMove(toParent: self)

        addChild(sendViewController)
        sendViewController.didMove(toParent: self)

        view.addSubview(mapViewController.view)
        view.addSubview(sendViewController.view)
        view.addSubview(locationButton)

        let action = UIAction { [weak self] _ in
            self?.locationButtonTapped()
        }

        locationButton.addAction(action, for: .touchUpInside)
    }

    private func createConstraints() {
        guard let sendController = sendViewController.view else { return }

        [mapViewController.view, sendController, locationButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        sendControllerHeightConstraint = sendController.heightAnchor.constraint(
            equalToConstant: LayoutConstants.sendControllerHeight + sendController.safeAreaInsets.bottom
        )

        sendControllerHeightConstraint?.isActive = false

        NSLayoutConstraint.activate([
            mapViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            mapViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sendController.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sendController.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sendController.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            locationButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: LayoutConstants.locationButtonLeadingOffset
            ),
            locationButton.bottomAnchor.constraint(
                equalTo: sendController.topAnchor,
                constant: LayoutConstants.locationButtonBottomOffset
            ),
            locationButton.widthAnchor.constraint(equalToConstant: LayoutConstants.locationButtonWidth),
            locationButton.heightAnchor.constraint(equalToConstant: LayoutConstants.locationButtonHeight)
        ])
    }

    // MARK: - User Actions

    private func locationButtonTapped() {
        mapViewController.zoomToUserLocation(animated: true)
    }

    // MARK: - Helpers

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
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
        geocoder
            .reverseGeocodeLocation(
                mapViewController.mapView.centerCoordinate
                    .location
            ) { [weak self] placemarks, error in
                guard error == nil, let placemark = placemarks?.first else { return }
                if let address = placemark.formattedAddress(false), !address.isEmpty {
                    self?.sendViewController.updateSelectedAddress(address)
                } else {
                    self?.sendViewController.updateSelectedAddress(nil)
                }
            }
    }

    private func updateSelectedLocationPayload() {
        sendViewController.updateSelectedLocation(
            latitude: Float(mapViewController.mapView.centerCoordinate.latitude),
            longitude: Float(mapViewController.mapView.centerCoordinate.longitude),
            zoomLevel: Int32(mapViewController.mapView.zoomLevel)
        )
    }

    private func handle(_ effects: [LocationSelectionViewModel.Effect]) {
        for effect in effects {
            switch effect {
            case .zoomToUserLocation:
                mapViewController.zoomToUserLocation(animated: true)
            case .setInitialRegionToUserLocation:
                break
            case .updateSelectedLocationPayload:
                updateSelectedLocationPayload()
            case .reverseGeocodeSelectedLocation:
                formatAndUpdateAddress()
            case .requestLocationAuthorization:
                appLocationManager.requestLocationAuthorization()
            case .presentUnauthorizedAlert:
                presentUnauthorizedAlert()
            case .startUpdatingLocation:
                appLocationManager.startUpdatingLocation()
            case .showUserLocation:
                mapViewController.mapView.showsUserLocation = true
            }
        }
    }
}

// MARK: - LocationSendViewControllerDelegate

extension LocationSelectionViewController: LocationSendViewControllerDelegate {
    func locationSendViewController(_ viewController: LocationSendViewController, shouldChangeHeight isActive: Bool) {
        sendControllerHeightConstraint?.isActive = isActive

        if isActive {
            guard let window = view.window else { return }

            let bottomInset = window.safeAreaInsets.bottom
            sendControllerHeightConstraint?.constant = 56 + bottomInset
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    func locationSendViewControllerSendButtonTapped(_ viewController: LocationSendViewController) {
        updateSelectedLocationPayload()
        guard let locationData = viewController.selectedLocationData else { return }
        delegate?.locationSelectionViewController(self, didSelectLocationWithData: locationData)
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Map Manager Delegate

extension LocationSelectionViewController: MapViewControllerDelegate {
    func mapViewController(_ viewController: MapViewController, didUpdateUserLocation userLocation: MKUserLocation) {
        handle(viewModel.perform(.mapDidUpdateUserLocation))
    }

    func mapViewController(_ viewController: MapViewController, regionDidChangeAnimated animated: Bool) {
        handle(viewModel.perform(.mapRegionDidChange))
    }

    func mapViewControllerDidFinishRenderingMap(_ viewController: MapViewController, fullyRendered: Bool) {
        handle(viewModel.perform(.mapDidFinishRendering))
    }
}

// MARK: - AppLocation Manager Delegate

extension LocationSelectionViewController: AppLocationManagerDelegate {
    func didUpdateLocations(_ locations: [CLLocation]) {
        guard let newLocation = locations.first else { return }

        for effect in viewModel.perform(.appLocationDidUpdate) {
            guard case .setInitialRegionToUserLocation = effect else {
                handle([effect])
                continue
            }

            mapViewController.setRegion(
                to: newLocation.coordinate,
                latitudinalMeters: 50,
                longitudinalMeters: 50,
                animated: true
            )
        }
    }

    func didFailWithError(_ error: Error) {
        let alertController = UIAlertController(
            title: L10n.Localizable.Location.Error.Alert.title,
            message: L10n.Localizable.Location.Error.Alert.description,
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: L10n.Localizable.General.ok, style: .default, handler: nil)
        alertController.addAction(okAction)

        present(alertController, animated: true, completion: nil)
    }

    func didChangeAuthorization(status: CLAuthorizationStatus) {
        handle(viewModel.perform(.authorizationDidChange(status.viewModelAuthorizationStatus)))
    }
}

private extension CLAuthorizationStatus {

    var viewModelAuthorizationStatus: LocationSelectionViewModel.AuthorizationStatus {
        switch self {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways:
            return .authorizedAlways
        case .authorizedWhenInUse:
            return .authorizedWhenInUse
        @unknown default:
            return .unknown
        }
    }

}
