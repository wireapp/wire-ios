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
import WireFoundation

/// A class which serves as bridge between the `SidebarView` and the `SidebarViewController`.
/// It's injected into the `SidebarAdapter` where changes are observed while the hosting controller also keeps a reference.
final class SidebarModel: ObservableObject {

    @Published var wireAccentColor: WireAccentColor = .default
    @Published var wireAccentColorMapping: WireAccentColorMapping?
    @Published var wireTextStyleMapping: WireTextStyleMapping?
    @Published var sidebarBackgroundColor: UIColor = .systemGray5
    @Published var sidebarAccountInfoViewDisplayNameColor: UIColor = .darkText
    @Published var sidebarAccountInfoViewUsernameColor: UIColor = .systemGray
    @Published var sidebarMenuItemTitleForegroundColor: UIColor = .darkText
    @Published var sidebarMenuItemLinkIconForegroundColor: UIColor = .systemGray
    @Published var sidebarMenuItemIsPressedTitleForegroundColor: UIColor = .systemBackground

    @Published var accountInfo = SidebarAccountInfo()
    @Published var selectedMenuItem: SidebarSelectableMenuItem = .all {
        didSet { menuItemAction(selectedMenuItem) }
    }

    let accountImageAction: () -> Void
    let menuItemAction: (_ selectedMenuItem: SidebarSelectableMenuItem) -> Void
    let connectAction: () -> Void
    let supportAction: () -> Void

    init(
        accountImageAction: @escaping () -> Void,
        menuItemAction: @escaping (_: SidebarSelectableMenuItem) -> Void,
        connectAction: @escaping () -> Void,
        supportAction: @escaping () -> Void
    ) {
        self.accountImageAction = accountImageAction
        self.menuItemAction = menuItemAction
        self.connectAction = connectAction
        self.supportAction = supportAction
    }
}
