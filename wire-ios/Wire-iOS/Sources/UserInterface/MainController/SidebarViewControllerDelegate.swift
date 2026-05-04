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
import WireFoundation
import WireMainNavigationUI
import WireSidebarUI

final class SidebarViewControllerDelegate: WireSidebarUI.SidebarViewControllerDelegate {

    let mainCoordinator: AnyMainCoordinator
    let connectUIBuilder: ConnectViewControllerBuilderProtocol
    let selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    let folderPickerViewControllerBuilder: FolderPickerViewControllerBuilder
    let analyticsEventTracker: () -> (any AnalyticsEventTrackerProtocol)?

    init(
        mainCoordinator: AnyMainCoordinator,
        connectUIBuilder: ConnectViewControllerBuilderProtocol,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        folderPickerViewControllerBuilder: FolderPickerViewControllerBuilder,
        analyticsEventTracker: @escaping () -> (any AnalyticsEventTrackerProtocol)?
    ) {
        self.mainCoordinator = mainCoordinator
        self.connectUIBuilder = connectUIBuilder
        self.selfProfileUIBuilder = selfProfileUIBuilder
        self.folderPickerViewControllerBuilder = folderPickerViewControllerBuilder
        self.analyticsEventTracker = analyticsEventTracker
    }

    public func sidebarViewControllerDidSelectAccountImage(_ viewController: SidebarViewController) {
        // analytics
        let isNotificationsBadgeVisible = viewController.accountInfo.showNotificationsBadge
        let analyticsEventTracker = analyticsEventTracker()
        #if false // [WPB-15245] This event has temporarily been disabled.
            analyticsEventTracker?.trackEvent(.UI.openSelfProfile(isMigrationDotActive: isNotificationsBadgeVisible))
        #endif

        // open profile
        Task { @MainActor in
            let rootViewController = selfProfileUIBuilder.build(mainCoordinator: mainCoordinator)
            let selfProfileUI = UINavigationController(rootViewController: rootViewController)
            selfProfileUI.modalPresentationStyle = .formSheet
            selfProfileUI.presentationController?.delegate = rootViewController
            await mainCoordinator.presentViewController(selfProfileUI)
        }
    }

    @MainActor
    func sidebarViewController(_ viewController: SidebarViewController, didTapFoldersMenuItem frame: CGRect) {
        Task {
            let folderPicker = folderPickerViewControllerBuilder.build(
                mainCoordinator: mainCoordinator,
                showCloseButton: false
            )
            folderPicker.modalPresentationStyle = .popover

            if let popover = folderPicker.popoverPresentationController,
               let view = viewController.view,
               let window = view.window {
                popover.sourceView = view
                popover.sourceRect = view.convert(frame, from: window)
            }

            viewController.present(folderPicker, animated: true)
        }
    }

    @MainActor
    public func sidebarViewController(
        _ viewController: SidebarViewController,
        didSelect menuItem: SidebarSelectableMenuItem
    ) {
        Task {
            switch menuItem {
            case .all:
                await mainCoordinator.showConversationList(conversationFilter: .none)
            case .favorites:
                await mainCoordinator.showConversationList(conversationFilter: .favorites)
            case .groups:
                await mainCoordinator.showConversationList(conversationFilter: .groups)
            case .channels:
                await mainCoordinator.showConversationList(conversationFilter: .channels)
            case .oneOnOne:
                await mainCoordinator.showConversationList(conversationFilter: .oneOnOne)
            case .unread:
                await mainCoordinator.showConversationList(conversationFilter: .unread)
            case .mentions:
                await mainCoordinator.showConversationList(conversationFilter: .mentions)
            case .replies:
                await mainCoordinator.showConversationList(conversationFilter: .replies)
            case .drafts:
                await mainCoordinator.showConversationList(conversationFilter: .drafts)
            case .folders:
                break // handled by `sidebarViewController(_:didTapFoldersAt:)`
            case .archive:
                await mainCoordinator.showArchive()
            case .settings:
                await mainCoordinator.showSettings()
            case .meetings:
                await mainCoordinator.showMeetings()
            case .files:
                await mainCoordinator.showFiles()
            }
        }
    }

    @MainActor
    public func sidebarViewControllerDidSelectSupport(_ viewController: SidebarViewController) {
        if let browser = WireURLs.shared.support.browserControllerOrOpenExternally() {
            Task {
                await mainCoordinator.presentViewController(browser)
            }
        }
    }
}
