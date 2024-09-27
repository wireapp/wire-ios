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

final class SettingsProfileLinkCellDescriptor: SettingsCellDescriptorType {
    // MARK: Internal

    static let cellType: SettingsTableCellProtocol.Type = SettingsLinkTableCell.self

    var identifier: String?
    weak var group: SettingsGroupCellDescriptorType?
    var previewGenerator: PreviewGeneratorType?

    // MARK: - SettingsCellDescriptorType

    var visible: Bool {
        true
    }

    var title: String {
        L10n.Localizable.Self.Settings.AccountSection.ProfileLink.title
    }

    // MARK: - Configuration

    func featureCell(_ cell: SettingsCellType) {
        guard let linkCell = cell as? SettingsLinkTableCell else {
            return
        }

        linkCell.linkText = link && .lineSpacing(8)
        linkCell.titleText = title
    }

    func select(_ value: SettingsPropertyValue, sender: UIView) {
        // no-op
    }

    // MARK: Private

    private var link: String {
        URL.selfUserProfileLink?.absoluteString.removingPercentEncoding ?? ""
    }
}
