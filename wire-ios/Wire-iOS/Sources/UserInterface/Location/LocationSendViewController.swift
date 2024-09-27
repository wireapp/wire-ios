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

import UIKit
import WireCommonComponents
import WireDesign

// MARK: - LocationSendViewControllerDelegate

protocol LocationSendViewControllerDelegate: AnyObject {
    func locationSendViewControllerSendButtonTapped(_ viewController: LocationSendViewController)
    func locationSendViewController(_ viewController: LocationSendViewController, shouldChangeHeight isActive: Bool)
}

// MARK: - LocationSendViewController

final class LocationSendViewController: UIViewController {
    // MARK: Internal

    weak var delegate: LocationSendViewControllerDelegate?

    var address: String? {
        didSet {
            addressLabel.text = address
            updateAddressLabelAccessibility()
            let shouldActivateConstraint = address?.isEmpty ?? true
            delegate?.locationSendViewController(self, shouldChangeHeight: shouldActivateConstraint)
        }
    }

    // MARK: - viewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSendLocationButton()
        setupAddressLabel()
        setupContainerView()
        createConstraints()
        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    // MARK: Private

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

    // MARK: - Setup UI and constraints

    private func setupSendLocationButton() {
        sendButton.setTitle(L10n.Localizable.Location.SendButton.title, for: [])

        let action = UIAction { [weak self] _ in
            self?.sendButtonTapped()
        }
        sendButton.addAction(action, for: .touchUpInside)
        sendButton.accessibilityIdentifier = "sendLocation"
    }

    private func setupAddressLabel() {
        addressLabel.accessibilityIdentifier = "selectedAddress"
        addressLabel.accessibilityTraits = .staticText
        updateAddressLabelAccessibility()
    }

    private func updateAddressLabelAccessibility() {
        addressLabel.accessibilityLabel = L10n.Accessibility.SendLocation.Address.description(addressLabel)
        addressLabel.accessibilityHint = L10n.Accessibility.SendLocation.Address.hint
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
            sendButton.centerYAnchor.constraint(equalTo: addressLabel.centerYAnchor),
        ])

        sendButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        addressLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        addressLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    // MARK: - Action

    private func sendButtonTapped() {
        guard let delegate else { return }
        delegate.locationSendViewControllerSendButtonTapped(self)
    }
}
