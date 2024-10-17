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

import WireMainNavigationUI
import WireSidebarUI

// TODO: [WPB-11651] Create a dedicated delegate type for the sidebar and let it use the main coordinator.

extension MainCoordinator: SidebarViewControllerDelegate where Dependencies.ConversationFilter == Wire.ConversationFilter {

    @MainActor
    public func sidebarViewControllerDidSelectAccountImage(_ viewController: SidebarViewController) {
        Task {
            await showSelfProfile()
        }
    }

    @MainActor
    public func sidebarViewController(_ viewController: SidebarViewController, didSelect menuItem: SidebarSelectableMenuItem) {
        Task {
            switch menuItem {
            case .all:
                await showConversationList(conversationFilter: .none)
            case .favorites:
                await showConversationList(conversationFilter: .favorites)
            case .groups:
                await showConversationList(conversationFilter: .groups)
            case .oneOnOne:
                await showConversationList(conversationFilter: .oneOnOne)
            case .archive:
                await showArchive()
            case .settings:
                await showSettings()
            }
        }
    }

    public func sidebarViewControllerDidSelectConnect(_ viewController: SidebarViewController) {
        Task {
            await showConnect()
        }
    }

    @MainActor
    public func sidebarViewControllerDidSelectSupport(_ viewController: SidebarViewController) {
        let url = WireURLs.shared.support
        let browser = BrowserViewController(url: url)
        browser.modalPresentationCapturesStatusBarAppearance = true
        Task {
            await presentViewController(browser)
        }
    }
}
