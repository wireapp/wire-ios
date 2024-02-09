//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import Foundation
import UIKit
import WireCommonComponents
import WireDataModel

final class UserClientCell: SeparatorCollectionViewCell {

    enum EdgeInsetConstants {
        static let small: CGFloat = 2.0
        static let medium: CGFloat = 4.0
        static let normal: CGFloat = 8.0
        static let `default`: CGFloat = 16.0
    }

    typealias LabelColors = SemanticColors.Label
    typealias IconColors = SemanticColors.Icon

    // MARK: - Properties
    let nameLabel = DynamicFontLabel(style: .headline,
                                     color: LabelColors.textDefault)
    let labelLabel = DynamicFontLabel(style: .subheadline,
                                      color: LabelColors.textDefault)
    let mlsThumbprintLabel = DynamicFontLabel(style: .caption1,
                                        color: LabelColors.textCellSubtitle)
    let proteusIdLabel = DynamicFontLabel(style: .caption1,
                                            color: LabelColors.textCellSubtitle)

    private let statusStackView = UIStackView()
    private let contentWrapView = UIView()
    private let contentStackView = UIStackView()
    private let accessoryIconView = UIImageView()

    var showLabel: Bool = false {
        didSet {
            updateLabel()
        }
    }

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
            updateLabel()
            setupAccessibility()
        }
    }

    private let verifiedImage = Asset.Images.verifiedShield.image.resizableImage(withCapInsets: .zero)
    private var mlsInfoHeighConstraint: NSLayoutConstraint { mlsThumbprintLabel.heightAnchor.constraint(equalToConstant: 0)
    }

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        createConstraints()
        setupStyle()
    }

    @available(*, unavailable)
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .center
        accessoryIconView.setTemplateIcon(.disclosureIndicator, size: 12)
        accessoryIconView.tintColor = IconColors.foregroundDefault
    }

    private func createConstraints() {
        [
            nameLabel,
            labelLabel,
            proteusIdLabel,
            mlsThumbprintLabel,
            statusStackView
        ].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            contentWrapView.addSubview(view)
        }
        contentWrapView.translatesAutoresizingMaskIntoConstraints = false

        statusStackView.axis = .horizontal
        contentStackView.addArrangedSubview(contentWrapView)
        contentStackView.addArrangedSubview(accessoryIconView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentStackView)
        // Setting the constraints for the view
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentWrapView.topAnchor, constant: EdgeInsetConstants.default),
            nameLabel.leftAnchor.constraint(equalTo: contentWrapView.leftAnchor, constant: EdgeInsetConstants.default),
            nameLabel.rightAnchor.constraint(lessThanOrEqualTo: contentWrapView.rightAnchor, constant: -EdgeInsetConstants.default),

            labelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: EdgeInsetConstants.small),
            labelLabel.leftAnchor.constraint(equalTo: contentWrapView.leftAnchor, constant: EdgeInsetConstants.default),
            labelLabel.rightAnchor.constraint(lessThanOrEqualTo: contentWrapView.rightAnchor, constant: -EdgeInsetConstants.default),

            statusStackView.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: EdgeInsetConstants.small),
            statusStackView.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: EdgeInsetConstants.medium),
            statusStackView.rightAnchor.constraint(lessThanOrEqualTo: contentWrapView.rightAnchor, constant: -EdgeInsetConstants.default),

            mlsThumbprintLabel.topAnchor.constraint(equalTo: labelLabel.bottomAnchor, constant: EdgeInsetConstants.medium),
            mlsThumbprintLabel.leftAnchor.constraint(equalTo: contentWrapView.leftAnchor, constant: EdgeInsetConstants.default),
            mlsThumbprintLabel.rightAnchor.constraint(lessThanOrEqualTo: contentWrapView.rightAnchor, constant: -EdgeInsetConstants.default),

            proteusIdLabel.topAnchor.constraint(equalTo: mlsThumbprintLabel.bottomAnchor),
            proteusIdLabel.leftAnchor.constraint(equalTo: contentWrapView.leftAnchor, constant: EdgeInsetConstants.default),
            proteusIdLabel.rightAnchor.constraint(lessThanOrEqualTo: contentWrapView.rightAnchor, constant: -EdgeInsetConstants.default),
            proteusIdLabel.bottomAnchor.constraint(equalTo: contentWrapView.bottomAnchor, constant: -EdgeInsetConstants.default),

            contentStackView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            contentStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -EdgeInsetConstants.default),
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
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

    override func prepareForReuse() {
        viewModel = nil
        super.prepareForReuse()
    }

    private func setupAccessibility() {
        typealias ClientListStrings = L10n.Accessibility.ClientsList

        guard let deviceName = nameLabel.text,
              let deviceId = proteusIdLabel.text else {
                  isAccessibilityElement = false
                  return
              }

        isAccessibilityElement = true
        accessibilityTraits = .button

        let proteusVerificationStatus = viewModel?.isProteusVerified ?? false
                                    ? ClientListStrings.DeviceVerified.description
                                    : ClientListStrings.DeviceNotVerified.description
        let mlsThumbprintLabelText = viewModel?.mlsThumbprintLabelText ?? ""
        let e2eIdentityStatus = viewModel?.e2eIdentityStatus?.title ?? ""
        var accessbilityContent = deviceName
        accessbilityContent += ", " + mlsThumbprintLabelText
        accessbilityContent += ", " + deviceId
        accessbilityContent += ", " + e2eIdentityStatus
        accessbilityContent += ", " + proteusVerificationStatus
        accessibilityLabel = accessbilityContent
        accessibilityHint = ClientListStrings.DeviceDetails.hint
    }
}
