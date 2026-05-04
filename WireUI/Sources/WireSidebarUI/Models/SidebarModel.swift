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

import UIKit
import WireDesign
import WireFoundation

/// A class which serves as bridge between the `SidebarView` and the `SidebarViewController`.
/// It's injected into the `SidebarAdapter` where changes are observed while the hosting controller also keeps a
/// reference.

final class SidebarModel: ObservableObject {

    @Published var wireAccentColor: WireAccentColor = .default
    @Published var sidebarBackgroundColor: UIColor = .systemGray5
    @Published var sidebarAccountInfoViewDisplayNameColor: UIColor = defaultTextColor
    @Published var sidebarAccountInfoViewUsernameColor: UIColor = .gray
    @Published var sidebarMenuHeaderForegroundColor: UIColor = defaultTextColor
    @Published var sidebarMenuItemTitleForegroundColor: UIColor = defaultTextColor
    @Published var sidebarMenuItemLinkIconForegroundColor: UIColor = .systemGray
    @Published var sidebarMenuItemIsSelectedTitleForegroundColor: UIColor = .systemBackground

    @Published var accountInfo = SidebarAccountInfo()
    @Published var selectedMenuItem: SidebarSelectableMenuItem = .all {
        didSet { menuItemAction(selectedMenuItem) }
    }

    @Published var showUnreadFilters: Bool = false
    @Published var showMeetings: Bool = false
    @Published var showFiles: Bool = false

    let accountImageAction: () -> Void
    let menuItemAction: (_ selectedMenuItem: SidebarSelectableMenuItem) -> Void
    let foldersAction: (CGRect) -> Void
    let supportAction: () -> Void

    init(
        accountImageAction: @escaping () -> Void,
        menuItemAction: @escaping (SidebarSelectableMenuItem) -> Void,
        foldersAction: @escaping (_ buttonFrame: CGRect) -> Void,
        supportAction: @escaping () -> Void
    ) {
        self.accountImageAction = accountImageAction
        self.foldersAction = foldersAction
        self.menuItemAction = menuItemAction
        self.supportAction = supportAction
    }
}

private let defaultTextColor = UIColor {
    $0.userInterfaceStyle == .dark ? .white : .darkText
}
