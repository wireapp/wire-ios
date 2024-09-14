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
import WireFoundation

final class RemoveClientTableViewCell: UITableViewCell {

    typealias LabelColors = SemanticColors.Label

    // MARK: - Properties

    private let deviceNameLabel = DynamicFontLabel(
        style: .h3,
        color: LabelColors.textDefault)

    private let proteusIdLabel = DynamicFontLabel(
        style: .subline1,
        color: LabelColors.textCellSubtitle)

    private let activationDateLabel = DynamicFontLabel(
        style: .subline1,
        color: LabelColors.textCellSubtitle)

    var viewModel: ClientTableViewCellModel? {
        didSet {
            deviceNameLabel.text = viewModel?.title
            if let date = viewModel?.activationDate?.formattedDate {
                activationDateLabel.text = L10n.Localizable.Registration.Devices.activated(date)
            }
            proteusIdLabel.text = viewModel?.proteusLabelText
        }
    }

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        createConstraints()
        setupStyle()
    }

    @available(*, unavailable)
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    private func setupStyle() {
        deviceNameLabel.accessibilityIdentifier = "device name"
        proteusIdLabel.accessibilityIdentifier = "device proteus ID"
        activationDateLabel.accessibilityIdentifier = "activation date"

        backgroundColor = SemanticColors.View.backgroundUserCell

        addBorder(for: .bottom)
    }

    private func createConstraints() {
        [
            deviceNameLabel,
            proteusIdLabel,
            activationDateLabel
        ].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }

        NSLayoutConstraint.activate([
            deviceNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            deviceNameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            deviceNameLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

            proteusIdLabel.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 10),
            proteusIdLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            proteusIdLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),

            activationDateLabel.topAnchor.constraint(equalTo: proteusIdLabel.bottomAnchor, constant: 10),
            activationDateLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            activationDateLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16),
            activationDateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

 }
