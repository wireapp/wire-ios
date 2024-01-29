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

    typealias LabelColors = SemanticColors.Label

    // MARK: - Properties
    let nameLabel = DynamicFontLabel(fontSpec: .normalSemiboldFont,
                                     color: LabelColors.textDefault)
    let labelLabel = DynamicFontLabel(fontSpec: .smallSemiboldFont,
                                      color: LabelColors.textDefault)
    let mlsThumbprintLabel = DynamicFontLabel(style: .caption1,
                                        color: LabelColors.textCellSubtitle)
    let proteusIdLabel = DynamicFontLabel(style: .caption1,
                                            color: LabelColors.textCellSubtitle)
    let proteusVerficiationStatusImageView = UIImageView()

    private let verifiedImage = Asset.Images.verifiedShield.image.resizableImage(withCapInsets: .zero)

    var showLabel: Bool = false {
        didSet {
            updateLabel()
        }
    }

    var viewModel: ClientTableViewCellModel? {
        didSet {
            guard let viewModel = viewModel else { return }
            nameLabel.text = viewModel.title
            proteusIdLabel.text = viewModel.proteusID
            mlsThumbprintLabel.text = viewModel.mlsThumbprint
            proteusVerficiationStatusImageView.image = viewModel.isProteusVerified ? verifiedImage : .none
            updateLabel()
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
        proteusIdLabel.accessibilityIdentifier = "device proteus ID"
        mlsThumbprintLabel.accessibilityIdentifier = "device mls thumbprint"
        mlsThumbprintLabel.numberOfLines = 1
        proteusIdLabel.numberOfLines = 1

        backgroundColor = SemanticColors.View.backgroundUserCell

        addBorder(for: .bottom)
    }

    private func createConstraints() {
        [
            nameLabel,
            labelLabel,
            proteusIdLabel,
            mlsThumbprintLabel,
            proteusVerficiationStatusImageView
        ].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }

        // Setting the constraints for the view
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            nameLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

            labelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            labelLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            labelLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

            proteusVerficiationStatusImageView.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            proteusVerficiationStatusImageView.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 8),
            proteusVerficiationStatusImageView.heightAnchor.constraint(equalToConstant: 16),
            proteusVerficiationStatusImageView.widthAnchor.constraint(equalToConstant: 16),

            mlsThumbprintLabel.topAnchor.constraint(equalTo: labelLabel.bottomAnchor, constant: 4),
            mlsThumbprintLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            mlsThumbprintLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

            proteusIdLabel.topAnchor.constraint(equalTo: mlsThumbprintLabel.bottomAnchor, constant: 0),
            proteusIdLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            proteusIdLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),
            proteusIdLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    private func updateLabel() {
        if let userClientLabel = viewModel?.label, showLabel {
            labelLabel.text = userClientLabel
        } else {
            labelLabel.text = ""
        }
    }

    func redrawFont() {
        updateLabel()
    }
}

extension ClientTableViewCellModel {

    private typealias DeviceDetailsSection = L10n.Localizable.Device.Details.Section

    static func from(userClient: UserClient) -> ClientTableViewCellModel {
        let title = userClient.isLegalHoldDevice ?  L10n.Localizable.Device.Class.legalhold : (userClient.model ?? "")

        let proteusId = userClient.displayIdentifier.fingerprintStringWithSpaces.uppercased()
        let proteusIdLabelText = DeviceDetailsSection.Proteus.value(proteusId)
        let isProteusVerified = userClient.verified

        let mlsThumbPrint = userClient.mlsPublicKeys.ed25519?.fingerprintStringWithSpaces ?? ""
        let mlsThumbprintLabelText = mlsThumbPrint.isNonEmpty ? DeviceDetailsSection.Mls.thumbprint(mlsThumbPrint) : ""

        return .init(title: title, label: userClient.label ?? "",
                     proteusID: proteusIdLabelText,
                     mlsThumbprint: mlsThumbprintLabelText,
                     isProteusVerified: isProteusVerified)
    }
}
