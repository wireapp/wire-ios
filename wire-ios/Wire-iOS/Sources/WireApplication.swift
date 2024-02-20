//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireCommonComponents
import WireSyncEngine
import SwiftUI

final class WireApplication: UIApplication {

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }

        if Bundle.developerModeEnabled {
            let developerTools = UIHostingController(
                rootView: NavigationView {
                    DeveloperToolsView(viewModel: DeveloperToolsViewModel(
                        router: AppDelegate.shared.appRootRouter,
                        onDismiss: { [weak self] in
                            self?.topmostViewController()?.dismissIfNeeded()
                        }
                    ))
                }
            )

            topmostViewController()?.present(developerTools, animated: true)
        } else {
            DebugAlert.showSendLogsMessage(
                message: "You have performed a shake motion, please confirm sending debug logs."
            )
        }
    }
}

extension WireApplication: NotificationSettingsRegistrable {
    var shouldRegisterUserNotificationSettings: Bool {
        return !(AutomationHelper.sharedHelper.skipFirstLoginAlerts || AutomationHelper.sharedHelper.disablePushNotificationAlert)
    }
}
