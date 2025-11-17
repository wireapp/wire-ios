//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import SwiftUI
import WireAccountImageUI
import WireDesign
import WireFoundation
import WireReusableUIComponents
import WireSidebarUI
import WireUtilities

struct SidebarViewControllerBuilder {

    @MainActor
    func build(isWireCellsEnabled: Bool = false) -> SidebarViewController {

        let accountImageViewDesign = AccountImageViewDesign()
        let availabilityIndicatorDesign = accountImageViewDesign.availabilityIndicator

        let legalHoldIndicatorViewDesign = LegalHoldIndicatorViewDesign()

        let sidebarViewController = SidebarViewController(
            accountImageView: { accountImage, availability, showNotificationsBadge in
                AccountImageViewRepresentable(
                    source: accountImage.mapToAccountImageSource(),
                    availability: availability?.mapToAccountImageAvailability(),
                    showNotificationsBadge: showNotificationsBadge
                )
                .accountImageBorderWidth(accountImageViewDesign.borderWidth)
                .accountImageViewBorderColor(accountImageViewDesign.borderColor)
                .availabilityIndicatorAvailableColor(availabilityIndicatorDesign.availableColor)
                .availabilityIndicatorAwayColor(availabilityIndicatorDesign.awayColor)
                .availabilityIndicatorBusyColor(availabilityIndicatorDesign.busyColor)
                .availabilityIndicatorBackgroundViewColor(availabilityIndicatorDesign.backgroundViewColor)
            },
            legalHoldIndicatorView: {
                LegalHoldIndicatorView()
                    .legalHoldIndicatorColor(Color(uiColor: legalHoldIndicatorViewDesign.foregroundColor))
            }
        )

        let sidebarDesign = SidebarViewDesign()
        sidebarViewController.sidebarBackgroundColor = sidebarDesign.backgroundColor
        sidebarViewController.sidebarAccountInfoViewDisplayNameColor = sidebarDesign.accountInfoViewDisplayNameColor
        sidebarViewController.sidebarAccountInfoViewUsernameColor = sidebarDesign.accountInfoViewUsernameColor
        sidebarViewController.sidebarMenuItemTitleForegroundColor = sidebarDesign.menuItemTitleForegroundColor
        sidebarViewController.sidebarMenuItemLinkIconForegroundColor = sidebarDesign.menuItemLinkIconForegroundColor
        sidebarViewController.sidebarMenuItemIsSelectedTitleForegroundColor = sidebarDesign
            .menuItemIsSelectedTitleForegroundColor

        // Configure unread filters visibility based on feature flag
        sidebarViewController.showUnreadFilters = DeveloperFlag.showUnreadConversationsFilter.isOn
        sidebarViewController.showMeetings = DeveloperFlag.wireMeetings.isOn
        sidebarViewController.showFiles = isWireCellsEnabled

        return sidebarViewController
    }
}
