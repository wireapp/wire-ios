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
import CoreLocation
import Contacts
import WireDataModel
import WireCommonComponents

class ClientTableViewCell: UITableViewCell, DynamicTypeCapable {

    // MARK: - Properties
    typealias LabelColors = SemanticColors.Label

    let proteusVerficiationStatusImageView = UIImageView()

    let nameLabel =  DynamicFontLabel(fontSpec: .normalBoldFont, color: SemanticColors.Label.textDefault)
    let labelLabel = DynamicFontLabel(fontSpec: .smallLightFont, color: SemanticColors.Label.textDefault)
    let proteusIDLabel = DynamicFontLabel(fontSpec: .mediumRegularFont, color: SemanticColors.Label.textCellSubtitle)
    let mlsThumbprintLabel = DynamicFontLabel(fontSpec: .mediumRegularFont, color: SemanticColors.Label.textCellSubtitle)

    private let activationLabelFont = FontSpec.smallLightFont
    private let activationLabelDateFont = FontSpec.smallSemiboldFont

    var showVerified: Bool = false {
        didSet {
            updateVerifiedLabel()
        }
    }

    var showLabel: Bool = false {
        didSet {
            updateLabel()
        }
    }

    private typealias deviceDetailsSection = L10n.Localizable.Device.Details.Section

    var userClient: UserClient? {
        didSet {
            guard let userClient = userClient else { return }
            if let userClientModel = userClient.model {
                nameLabel.text = userClientModel
            } else if userClient.isLegalHoldDevice {
                nameLabel.text = L10n.Localizable.Device.Class.legalhold
            }

            updateLabel()
            updateFingerprint()
            updateVerifiedLabel()
        }
    }

    var wr_editable: Bool

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        wr_editable = true
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        createConstraints()
        setupStyle()
    }

    @available(*, unavailable)
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override method
    override func setEditing(_ editing: Bool, animated: Bool) {
        if wr_editable {
            super.setEditing(editing, animated: animated)
        }
    }

    // MARK: - Methods
    func setupStyle() {
        nameLabel.accessibilityIdentifier = "device name"
        labelLabel.accessibilityIdentifier = "device label"
        proteusIDLabel.accessibilityIdentifier = "device proteus ID"
        mlsThumbprintLabel.accessibilityIdentifier = "device mls thumbprint"
        mlsThumbprintLabel.numberOfLines = 1
        proteusIDLabel.numberOfLines = 1

        backgroundColor = SemanticColors.View.backgroundUserCell

        addBorder(for: .bottom)
    }

    private func createConstraints() {
        [
            nameLabel,
            labelLabel,
            proteusIDLabel,
            mlsThumbprintLabel,
            proteusVerficiationStatusImageView
        ].forEach(contentView.addSubview)
        [
            nameLabel,
            labelLabel,
            proteusIDLabel,
            mlsThumbprintLabel,
            proteusVerficiationStatusImageView
        ].prepareForLayout()

        // Setting the constraints for the view
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),

            proteusVerficiationStatusImageView.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            proteusVerficiationStatusImageView.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 8),
            proteusVerficiationStatusImageView.heightAnchor.constraint(equalToConstant: 16),
            proteusVerficiationStatusImageView.widthAnchor.constraint(equalToConstant: 16),
            proteusVerficiationStatusImageView.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

            labelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            labelLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            labelLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

            mlsThumbprintLabel.topAnchor.constraint(equalTo: labelLabel.bottomAnchor, constant: 4),
            mlsThumbprintLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            mlsThumbprintLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),
            mlsThumbprintLabel.heightAnchor.constraint(equalToConstant: 16),

            proteusIDLabel.topAnchor.constraint(equalTo: mlsThumbprintLabel.bottomAnchor, constant: 2),
            proteusIDLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            proteusIDLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),
            proteusIDLabel.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -16)

        ])
    }

    private func updateVerifiedLabel() {
        if let userClient = userClient,
           showVerified {
            if userClient.verified {
                proteusVerficiationStatusImageView.image = Asset.Images.verifiedShield.image
            } else {
                proteusVerficiationStatusImageView.image = .none
            }
        } else {
            proteusVerficiationStatusImageView.image = .none
        }
    }

    private func updateFingerprint() {
        guard let userClient = userClient else {
            return
        }
        proteusIDLabel.text =  deviceDetailsSection.Proteus.id
        + ": "
        + userClient.displayIdentifier.fingerprintStringWithSpaces.uppercased()

        mlsThumbprintLabel.text =  deviceDetailsSection.Mls.title
        + ": "
        + (userClient.mlsPublicKeys.ed25519?.fingerprintStringWithSpaces.uppercased() ?? "")
    }

    private func updateLabel() {
        if let userClientLabel = userClient?.label, showLabel {
            labelLabel.text = userClientLabel
        } else {
            labelLabel.text = ""
        }
    }

    func redrawFont() {
        updateFingerprint()
        updateLabel()
    }
}
