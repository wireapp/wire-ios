//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireFoundation

public enum SettingsTopLevelMenuItem: Sendable {
    case account
    case devices
    case options
    case advanced
    case support
    case about
    case developerOptions
}

// MARK: - Accessibility identifiers
extension SettingsTopLevelMenuItem {
    public var accessibilityID: String {
        switch self {
        case .account: return Locators.SettingsPage.accountCell.rawValue
        case .devices: return "devicesCell"
        case .options: return Locators.SettingsPage.optionsCell.rawValue
        case .advanced: return "advancedCell"
        case .support: return "supportCell"
        case .about: return "aboutCell"
        case .developerOptions: return "developerOptionsCell"
        }
    }
}
