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

import WireCommonComponents
import WireSyncEngine

final class WireApplication: UIApplication {

    private let developerToolsPresenter = DeveloperToolsPresenter()
    private let shareDebugPresenter = ShareDebugReportPresenter()

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        
        guard Bundle.developerModeEnabled else {
            // default behaviour
            presentDebugShareSheet()
            return
        }

        guard DeveloperFlag.shakeToReport.isOn else {
            // default internal builds behaviour
            presentDeveloperTools()
            return
        }

        guard shareDebugPresenter.isPresenting else {
            presentDebugShareSheet()
            return
        }

        // second gesture, go back to DeveloperTools
        shareDebugPresenter.dismiss { [weak self] in
            self?.presentDeveloperTools()
        }
    }
    
    private func presentDeveloperTools() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        self.developerToolsPresenter.presentIfNotDisplayed(
            with: appDelegate.appRootRouter,
            from: self.topmostViewController(onlyFullScreen: false)
        )
    }
    
    private func presentDebugShareSheet() {
        shareDebugPresenter.present(from: self.topmostViewController(onlyFullScreen: false))
    }

}

extension WireApplication: NotificationSettingsRegistrable {

    var shouldRegisterUserNotificationSettings: Bool {
        !(
            AutomationHelper.sharedHelper.skipFirstLoginAlerts || AutomationHelper.sharedHelper
                .disablePushNotificationAlert
        )
    }
}
