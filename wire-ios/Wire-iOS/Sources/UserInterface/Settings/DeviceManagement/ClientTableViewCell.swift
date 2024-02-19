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

final class ClientTableViewCell: UITableViewCell {

    typealias LabelColors = SemanticColors.Label

    // MARK: - Properties
    let nameLabel = DynamicFontLabel(style: .headline,
                                     color: LabelColors.textDefault)
    let mlsThumbprintLabel = DynamicFontLabel(style: .caption1,
                                        color: LabelColors.textCellSubtitle)
    let proteusIdLabel = DynamicFontLabel(style: .caption1,
                                            color: LabelColors.textCellSubtitle)
    let statusStackView = UIStackView()

    var viewModel: ClientTableViewCellModel? {
        didSet {
            nameLabel.text = viewModel?.title
            proteusIdLabel.text = viewModel?.proteusLabelText
            mlsThumbprintLabel.text = viewModel?.mlsThumbprintLabelText
            statusStackView.removeArrangedSubviews()
            if let e2eIdentityStatusImage = viewModel?.e2eIdentityStatus?.uiImage {
                statusStackView.addArrangedSubview(UIImageView(image: e2eIdentityStatusImage))
            }
            if viewModel?.isProteusVerified ?? false {
                statusStackView.addArrangedSubview(UIImageView(image: verifiedImage))
            }
        }
    }

    var wr_editable: Bool

    private let verifiedImage = Asset.Images.verifiedShield.image.resizableImage(withCapInsets: .zero)
    private var mlsInfoHeighConstraint: NSLayoutConstraint { mlsThumbprintLabel.heightAnchor.constraint(equalToConstant: 0)
    }

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
            proteusIdLabel,
            mlsThumbprintLabel,
            statusStackView
        ].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }
        // Setting the constraints for the view
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            nameLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

            statusStackView.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: 2),
            statusStackView.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 4),
            statusStackView.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

            mlsThumbprintLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            mlsThumbprintLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            mlsThumbprintLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

            proteusIdLabel.topAnchor.constraint(equalTo: mlsThumbprintLabel.bottomAnchor, constant: 0),
            proteusIdLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            proteusIdLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),
            proteusIdLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        statusStackView.axis = .horizontal
        statusStackView.spacing = 4
    }

    override func prepareForReuse() {
        viewModel = nil
        super.prepareForReuse()
    }
}

extension ClientTableViewCellModel {

    private typealias DeviceDetailsSection = L10n.Localizable.Device.Details.Section

    static func from(userClient: UserClientType, shouldSetType: Bool = true) -> ClientTableViewCellModel {
        var title = ""
        if shouldSetType {
            title = userClient.deviceClass == .legalHold ?
            L10n.Localizable.Device.Class.legalhold :
            (userClient.deviceClass?.localizedDescription.capitalized ?? userClient.type.localizedDescription.capitalized)
        } else {
            title = userClient.model ?? ""
        }
        let proteusId = userClient.displayIdentifier.fingerprintStringWithSpaces.uppercased()
        let proteusIdLabelText = DeviceDetailsSection.Proteus.value(proteusId)
        let isProteusVerified = userClient.verified

        let mlsThumbPrint = userClient.mlsThumbPrint?.fingerprintStringWithSpaces ?? ""
        let mlsThumbprintLabelText = mlsThumbPrint.isNonEmpty ? DeviceDetailsSection.Mls.thumbprint(mlsThumbPrint) : ""

        return .init(title: title,
                     proteusLabelText: proteusIdLabelText,
                     mlsThumbprintLabelText: mlsThumbprintLabelText,
                     isProteusVerified: isProteusVerified,
                     e2eIdentityStatus: userClient.e2eIdentityCertificate?.status)
    }
}
