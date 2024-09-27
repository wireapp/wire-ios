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

// MARK: - DeniedAuthorizationType

enum DeniedAuthorizationType {
    case camera
    case photos
    case cameraAndPhotos
    case ongoingCall
}

// MARK: - CameraKeyboardPermissionsCell

final class CameraKeyboardPermissionsCell: UICollectionViewCell {
    // MARK: - Properties

    let settingsButton = ZMButton(
        style: .secondaryTextButtonStyle,
        cornerRadius: 4,
        fontSpec: .normalSemiboldFont
    )
    let cameraIcon = IconButton()
    let descriptionLabel = UILabel()

    private let containerView = UIView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = SemanticColors.View.backgroundConversationView
        cameraIcon.setIcon(.cameraLens, size: .tiny, for: .normal)
        cameraIcon.setIconColor(SemanticColors.Icon.foregroundDefaultBlack, for: .normal)
        cameraIcon.isUserInteractionEnabled = false

        descriptionLabel.backgroundColor = .clear
        descriptionLabel.textColor = SemanticColors.Label.textDefault
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        settingsButton.setTitle(L10n.Localizable.KeyboardPhotosAccess.Denied.Keyboard.settings, for: .normal)
        settingsButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
        settingsButton.layer.masksToBounds = true
        settingsButton.addTarget(
            self,
            action: #selector(CameraKeyboardPermissionsCell.openSettings),
            for: .touchUpInside
        )

        containerView.backgroundColor = .clear

        containerView.addSubview(descriptionLabel)

        if SecurityFlags.cameraRoll.isEnabled { addSubview(containerView) }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    convenience init(frame: CGRect, deniedAuthorization: DeniedAuthorizationType) {
        self.init(frame: frame)
        configure(deniedAuthorization: deniedAuthorization)
    }

    // MARK: - Configure elements

    func configure(deniedAuthorization: DeniedAuthorizationType) {
        typealias KeyboardPhotoAccessDeniedLocale = L10n.Localizable.KeyboardPhotosAccess.Denied.Keyboard
        var title: String = switch deniedAuthorization {
        case .camera:           KeyboardPhotoAccessDeniedLocale.camera
        case .photos:           KeyboardPhotoAccessDeniedLocale.photos
        case .cameraAndPhotos:  KeyboardPhotoAccessDeniedLocale.cameraAndPhotos
        case .ongoingCall:      KeyboardPhotoAccessDeniedLocale.ongoingCall
        }

        descriptionLabel.font = UIFont.systemFont(
            ofSize: deniedAuthorization == .ongoingCall ? 14.0 : 16.0,
            weight: UIFont.Weight.light
        )
        descriptionLabel.text = title

        if SecurityFlags.cameraRoll.isEnabled {
            createConstraints(deniedAuthorization: deniedAuthorization)
        }
    }

    // MARK: - Actions

    @objc
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - UI Constraints

    private func createConstraints(deniedAuthorization: DeniedAuthorizationType) {
        [
            containerView,
            descriptionLabel,
            settingsButton,
            cameraIcon,
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        var constraints: [NSLayoutConstraint] = [
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ]

        defer {
            NSLayoutConstraint.activate(constraints)
        }

        if deniedAuthorization == .ongoingCall {
            constraints.append(contentsOf: createConstraintsForOngoingCallAlert())
        } else {
            constraints.append(contentsOf: createConstraintsForPermissionsAlert())
        }
    }

    private func createConstraintsForPermissionsAlert() -> [NSLayoutConstraint] {
        if cameraIcon.superview != nil {
            cameraIcon.removeFromSuperview()
        }
        containerView.addSubview(settingsButton)

        return [
            settingsButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            settingsButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),
            settingsButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
        ]
    }

    private func createConstraintsForOngoingCallAlert() -> [NSLayoutConstraint] {
        if settingsButton.superview != nil {
            settingsButton.removeFromSuperview()
        }
        containerView.addSubview(cameraIcon)

        return [
            descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: cameraIcon.bottomAnchor, constant: 16),
            cameraIcon.topAnchor.constraint(equalTo: containerView.topAnchor),
            cameraIcon.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        ]
    }
}
