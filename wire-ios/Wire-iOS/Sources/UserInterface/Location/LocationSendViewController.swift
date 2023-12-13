//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

protocol LocationSendViewControllerDelegate: AnyObject {
    func locationSendViewControllerSendButtonTapped(_ viewController: LocationSendViewController)
}

final class LocationSendViewController: UIViewController {

    let sendButton = Button(style: .accentColorTextButtonStyle, cornerRadius: 12, fontSpec: .normalSemiboldFont)

    let addressLabel: UILabel = {
        let label = DynamicFontLabel(style: .body, color: SemanticColors.Label.textDefault)
        label.numberOfLines = 0
        return label
    }()

    private let containerView = UIView()

    weak var delegate: LocationSendViewControllerDelegate?

    var address: String? {
        didSet {
            addressLabel.text = address
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        setupConstraints()

        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    private func configureViews() {
        sendButton.setTitle(L10n.Localizable.Location.SendButton.title, for: [])

        let action = UIAction { [weak self] _ in
            self?.sendButtonTapped()
        }
        sendButton.addAction(action, for: .touchUpInside)
        sendButton.accessibilityIdentifier = "sendLocation"
        addressLabel.accessibilityIdentifier = "selectedAddress"

        view.addSubview(containerView)
        [addressLabel, sendButton].forEach(containerView.addSubview)
    }

    private func setupConstraints() {
        [containerView, addressLabel, sendButton].prepareForLayout()
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            addressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            addressLabel.trailingAnchor.constraint(lessThanOrEqualTo: sendButton.leadingAnchor, constant: -12),
            addressLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            addressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            sendButton.centerYAnchor.constraint(equalTo: addressLabel.centerYAnchor),
            sendButton.heightAnchor.constraint(equalToConstant: 28)
        ])

        sendButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        addressLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        addressLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    private func sendButtonTapped() {
        delegate?.locationSendViewControllerSendButtonTapped(self)
    }
}
