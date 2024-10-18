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

import WireAccountImageUI
import WireDataModel
import WireSidebarUI

extension WireDataModel.Availability {

    /// Since `WireAccountImageUI` does not know about the type `WireDataModel.Availability`,
    /// this function serves as an adapter from `WireDataModel.Availability` to `WireAccountImageUI.Availability?`.

    func map() -> WireAccountImageUI.Availability? {
        switch self {
        case .none: .none
        case .available: .available
        case .busy: .busy
        case .away: .away
        }
    }
}

extension WireDataModel.Availability {

    /// Since `WireSidebarUI` does not know about the type `WireDataModel.Availability`,
    /// this function serves as an adapter from `WireDataModel.Availability` to `WireSidebarUI.SidebarAccountInfo.Availability?`.

    func map() -> WireSidebarUI.SidebarAccountInfo.Availability? {
        switch self {
        case .none: .none
        case .available: .available
        case .busy: .busy
        case .away: .away
        }
    }
}

extension WireSidebarUI.SidebarAccountInfo.Availability {

    /// Since `WireSidebarUI` does not know about the type `WireAccountImageUI.Availability`,
    /// this function serves as an adapter from `WireAccountImageUI.Availability` to `WireSidebarUI.SidebarAccountInfo.Availability?`.

    func map() -> WireAccountImageUI.Availability {
        switch self {
        case .available: .available
        case .busy: .busy
        case .away: .away
        }
    }
}
