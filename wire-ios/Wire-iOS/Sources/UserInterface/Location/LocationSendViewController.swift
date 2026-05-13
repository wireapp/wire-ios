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

import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign

// MARK: - LocationSendViewControllerDelegate

protocol LocationSendViewControllerDelegate: AnyObject {
    func locationSendViewControllerSendButtonTapped(_ viewController: LocationSendViewController)
    func locationSendViewController(_ viewController: LocationSendViewController, shouldChangeHeight isActive: Bool)

}

// MARK: - LocationSendViewController

final class LocationSendViewController: UIViewController {

    // MARK: - Properties

    private let sendButton = ZMButton(
        style: .accentColorTextButtonStyle,
        cornerRadius: 12,
        fontSpec: .normalSemiboldFont
    )

    private let addressLabel: UILabel = {
        let label = DynamicFontLabel(style: .body1, color: SemanticColors.Label.textDefault)
        label.numberOfLines = 0
        return label
    }()

    private let containerView = UIView()
    private let viewModel = LocationSendViewModel()

    weak var delegate: LocationSendViewControllerDelegate?

    var address: String? {
        get {
            viewModel.displayState.selectedAddress
        }
        set {
            updateSelectedAddress(newValue)
        }
    }

    var selectedLocationData: LocationData? {
        viewModel.displayState.selectedLocationPayload?.locationData
    }

    var canSend: Bool {
        viewModel.displayState.canSend
    }

    func updateSelectedAddress(_ address: String?) {
        let routes = viewModel.perform(.updateSelectedAddress(address))
        render(viewModel.displayState)
        handle(routes)
    }

    func updateSelectedLocation(latitude: Float, longitude: Float, zoomLevel: Int32) {
        viewModel.perform(.updateSelectedLocation(latitude: latitude, longitude: longitude, zoomLevel: zoomLevel))
        render(viewModel.displayState)
    }

    // MARK: - viewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSendLocationButton()
        setupAddressLabel()
        setupContainerView()
        createConstraints()
        view.backgroundColor = SemanticColors.View.backgroundDefault
        render(viewModel.displayState)
    }

    // MARK: - Setup UI and constraints

    private func setupSendLocationButton() {
        let action = UIAction { [weak self] _ in
            self?.sendButtonTapped()
        }
        sendButton.addAction(action, for: .touchUpInside)
    }

    private func setupAddressLabel() {
        addressLabel.accessibilityTraits = .staticText
    }

    private func render(_ state: LocationSendViewModel.DisplayState) {
        sendButton.setTitle(state.sendButtonTitle, for: [])
        sendButton.isEnabled = state.canSend
        sendButton.accessibilityIdentifier = state.sendButtonAccessibilityIdentifier

        addressLabel.text = state.selectedAddress
        addressLabel.accessibilityIdentifier = state.selectedAddressAccessibilityIdentifier
        addressLabel.accessibilityLabel = state.selectedAddressAccessibilityLabel
        addressLabel.accessibilityHint = state.selectedAddressAccessibilityHint
    }

    private func setupContainerView() {
        view.addSubview(containerView)
        [addressLabel, sendButton].forEach(containerView.addSubview)
    }

    private func createConstraints() {
        [containerView, addressLabel, sendButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            // containerView
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),

            // addressLabel
            addressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            addressLabel.trailingAnchor.constraint(lessThanOrEqualTo: sendButton.leadingAnchor, constant: -12),
            addressLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            addressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // sendButton
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            sendButton.centerYAnchor.constraint(equalTo: addressLabel.centerYAnchor)
        ])

        sendButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        addressLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        addressLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    // MARK: - Action

    private func sendButtonTapped() {
        handle(viewModel.perform(.sendButtonTapped))
    }

    private func handle(_ routes: [LocationSendViewModel.Route]) {
        for route in routes {
            switch route {
            case .send:
                delegate?.locationSendViewControllerSendButtonTapped(self)
            case let .updateHeight(shouldUseCompactHeight):
                delegate?.locationSendViewController(self, shouldChangeHeight: shouldUseCompactHeight)
            }
        }
    }

}
