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

public enum MainSidebarMenuItem: Sendable {
    // conversation filters
    case all, favorites, groups, oneOnOne, archive
    // contact
    case connect
    // bottom
    case settings
}

public protocol MainSidebarMenuItemRepresentable: Sendable {
    init(_ mainSidebarMenuItem: MainSidebarMenuItem)
    func map() -> MainSidebarMenuItem
}

extension MainSidebarMenuItem: MainSidebarMenuItemRepresentable {
    public init(_ mainSidebarMenuItem: MainSidebarMenuItem) { self = mainSidebarMenuItem }
    public func map() -> MainSidebarMenuItem { self }
}
