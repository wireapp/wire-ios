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

import WireAccountImage
import WireDataModel
import WireSidebar

extension WireDataModel.Availability {

    /// Since `WireAccountImage` does not know about the type `WireDataModel.Availability`,
    /// this function serves as an adapter from `WireDataModel.Availability` to `WireAccountImage.Availability?`.

    func map() -> WireAccountImage.Availability? {
        switch self {
        case .none: .none
        case .available: .available
        case .busy: .busy
        case .away: .away
        }
    }
}

extension WireDataModel.Availability {

    /// Since `WireSidebar` does not know about the type `WireDataModel.Availability`,
    /// this function serves as an adapter from `WireDataModel.Availability` to `WireSidebar.SidebarAccountInfo.Availability?`.

    func map() -> WireSidebar.SidebarAccountInfo.Availability? {
        switch self {
        case .none: .none
        case .available: .available
        case .busy: .busy
        case .away: .away
        }
    }
}

extension WireSidebar.SidebarAccountInfo.Availability {

    /// Since `WireSidebar` does not know about the type `WireAccountImage.Availability`,
    /// this function serves as an adapter from `WireAccountImage.Availability` to `WireSidebar.SidebarAccountInfo.Availability?`.

    func map() -> WireAccountImage.Availability {
        switch self {
        case .none: .none
        case .available: .available
        case .busy: .busy
        case .away: .away
        }
    }
}
