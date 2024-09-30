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

import WireSettings
import WireMainNavigation

extension SettingsTopLevelContent: MainSettingsContentRepresentable {

    public init(_ mainSettingsContent: MainSettingsContent) {
        switch mainSettingsContent {
        case .account:
            self = .account
        case .devices:
            self = .devices
        case .options:
            self = .options
        case .advanced:
            self = .advanced
        case .support:
            self = .support
        case .about:
            self = .about
        case .developerOptions:
            self = .developerOptions
        }
    }

    public func mapToMainSettingsContent() -> MainSettingsContent {
        switch self {
        case .account:
                .account
        case .devices:
                .devices
        case .options:
                .options
        case .advanced:
                .advanced
        case .support:
                .support
        case .about:
                .about
        case .developerOptions:
                .developerOptions
        }
    }
}
