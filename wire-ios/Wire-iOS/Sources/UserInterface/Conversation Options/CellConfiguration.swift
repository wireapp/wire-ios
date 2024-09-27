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

// MARK: - CellConfigurationConfigurable

protocol CellConfigurationConfigurable: Reusable {
    func configure(with configuration: CellConfiguration)
}

// MARK: - CellConfiguration

enum CellConfiguration {
    case linkHeader
    case secureLinkHeader
    case leadingButton(
        title: String,
        identifier: String,
        action: Action
    )
    case loading
    case text(String)
    case info(String)
    case iconAction(
        title: String,
        icon: StyleKitIcon,
        color: UIColor?,
        action: Action
    )
    case appearance(title: String)

    /// For toggle without icon, leave icon and color nil
    case iconToggle(
        title: String,
        subtitle: String,
        identifier: String,
        titleIdentifier: String,
        icon: StyleKitIcon?,
        color: UIColor?,
        isEnabled: Bool,
        get: () -> Bool,
        set: (Bool, UIView) -> Void
    )

    // MARK: Internal

    typealias Action = (UIView) -> Void

    // MARK: - Convenience

    static var allCellTypes: [UITableViewCell.Type] {
        [
            IconToggleSubtitleCell.self,
            LinkHeaderCell.self,
            SecureLinkHeaderCell.self,
            ActionCell.self,
            LoadingIndicatorCell.self,
            TextCell.self,
            GuestLinkInfoCell.self,
            IconActionCell.self,
            SettingsAppearanceCell.self,
        ]
    }

    var cellType: CellConfigurationConfigurable.Type {
        switch self {
        case .iconToggle: IconToggleSubtitleCell.self
        case .linkHeader: LinkHeaderCell.self
        case .secureLinkHeader: SecureLinkHeaderCell.self
        case .leadingButton: ActionCell.self
        case .loading: LoadingIndicatorCell.self
        case .text: TextCell.self
        case .info: GuestLinkInfoCell.self
        case .iconAction: IconActionCell.self
        case .appearance: SettingsAppearanceCell.self
        }
    }

    var action: Action? {
        switch self {
        case .appearance,
             .iconToggle,
             .info,
             .linkHeader,
             .loading,
             .secureLinkHeader,
             .text: nil
        case let .leadingButton(_, _, action: action): action
        case let .iconAction(_, _, _, action: action): action
        }
    }

    static func prepare(_ tableView: UITableView) {
        for cellType in allCellTypes {
            tableView.register(cellType, forCellReuseIdentifier: cellType.reuseIdentifier)
        }
    }
}
