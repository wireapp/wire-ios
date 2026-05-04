//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireMainNavigationUI
import WireSidebarUI

extension SidebarViewController: MainSidebarProtocol {}

extension SidebarSelectableMenuItem: MainSidebarSelectableMenuItemRepresentable {

    public init(_ mainSidebarMenuItem: MainSidebarMenuItem) {
        switch mainSidebarMenuItem {
        case .all: self = .all
        case .favorites: self = .favorites
        case .groups: self = .groups
        case .channels: self = .channels
        case .oneOnOne: self = .oneOnOne
        case .unread: self = .unread
        case .mentions: self = .mentions
        case .meetings: self = .meetings
        case .files: self = .files
        case .replies: self = .replies
        case .drafts: self = .drafts
        case .folders: self = .folders
        case .archive: self = .archive
        case .settings: self = .settings
        }
    }

    public func mapToMainSidebarMenuItem() -> MainSidebarMenuItem {
        switch self {
        case .all: .all
        case .favorites: .favorites
        case .groups: .groups
        case .channels: .channels
        case .oneOnOne: .oneOnOne
        case .unread: .unread
        case .mentions: .mentions
        case .meetings: .meetings
        case .files: .files
        case .replies: .replies
        case .drafts: .drafts
        case .folders: .folders
        case .archive: .archive
        case .settings: .settings
        }
    }
}
