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
import WireAnalytics
import WireCommonComponents
import WireMainNavigationUI
import WireSyncEngine

final class SelfProfileViewControllerBuilder: SelfProfileViewControllerBuilderProtocol {

    var selfUser: SettingsSelfUser
    var userRightInterfaceType: UserRightInterface.Type
    var userSession: UserSession
    var accountSelector: AccountSelector?
    var trackingManager: TrackingManager? // TODO: is this needed?
    var analyticsEventTracker: () -> (any AnalyticsEventTracker)?

    init(
        selfUser: SettingsSelfUser,
        userRightInterfaceType: UserRightInterface.Type,
        userSession: UserSession,
        accountSelector: AccountSelector?,
        analyticsEventTracker: @escaping () -> (any AnalyticsEventTracker)?
    ) {
        self.selfUser = selfUser
        self.userRightInterfaceType = userRightInterfaceType
        self.userSession = userSession
        self.accountSelector = accountSelector
        self.analyticsEventTracker = analyticsEventTracker
    }

    func build(mainCoordinator: AnyMainCoordinator) -> ViewController {
        SelfProfileViewController(
            selfUser: selfUser,
            userRightInterfaceType: userRightInterfaceType,
            userSession: userSession,
            accountSelector: accountSelector,
            mainCoordinator: mainCoordinator,
            trackingManager: trackingManager,
            analyticsEventTracker: analyticsEventTracker()
        )
    }
}
