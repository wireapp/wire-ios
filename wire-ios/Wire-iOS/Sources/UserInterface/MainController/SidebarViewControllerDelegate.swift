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
import WireMainNavigationUI
import WireSidebarUI

final class SidebarViewControllerDelegate: WireSidebarUI.SidebarViewControllerDelegate {

    let mainCoordinator: AnyMainCoordinator
    let connectUIBuilder: ConnectViewControllerBuilderProtocol
    let selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol

    init(
        mainCoordinator: AnyMainCoordinator,
        connectUIBuilder: ConnectViewControllerBuilderProtocol,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    ) {
        self.mainCoordinator = mainCoordinator
        self.connectUIBuilder = connectUIBuilder
        self.selfProfileUIBuilder = selfProfileUIBuilder
    }

    @MainActor
    public func sidebarViewControllerDidSelectAccountImage(_ viewController: SidebarViewController) {
        Task {
            let selfProfileUI = UINavigationController(rootViewController: selfProfileUIBuilder.build())
            selfProfileUI.modalPresentationStyle = .formSheet
            await mainCoordinator.presentViewController(selfProfileUI)
        }
    }

    @MainActor
    public func sidebarViewController(_ viewController: SidebarViewController, didSelect menuItem: SidebarSelectableMenuItem) {
        Task {
            switch menuItem {
            case .all:
                await mainCoordinator.showConversationList(conversationFilter: .none)
            case .favorites:
                await mainCoordinator.showConversationList(conversationFilter: .favorites)
            case .groups:
                await mainCoordinator.showConversationList(conversationFilter: .groups)
            case .oneOnOne:
                await mainCoordinator.showConversationList(conversationFilter: .oneOnOne)
            case .archive:
                await mainCoordinator.showArchive()
            case .settings:
                await mainCoordinator.showSettings()
            }
        }
    }

    public func sidebarViewControllerDidSelectConnect(_ viewController: SidebarViewController) {
        Task {
            let connectUI = connectUIBuilder.build(mainCoordinator: mainCoordinator)
            connectUI.modalPresentationStyle = .formSheet
            await mainCoordinator.presentViewController(connectUI)
        }
    }

    @MainActor
    public func sidebarViewControllerDidSelectSupport(_ viewController: SidebarViewController) {
        let url = WireURLs.shared.support
        let browser = BrowserViewController(url: url)
        browser.modalPresentationCapturesStatusBarAppearance = true
        Task {
            await mainCoordinator.presentViewController(browser)
        }
    }
}
