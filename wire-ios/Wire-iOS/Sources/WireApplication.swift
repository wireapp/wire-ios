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

    private let presenter = DeveloperToolsPresenter()
    private var tripleTapGestureRecognizer: UITapGestureRecognizer?

    override init() {
        super.init()
        setupTripleTapGestureForSimulator()
    }

    // Triple tap gesture for simulator (used in XCUITests)
    private func setupTripleTapGestureForSimulator() {
        #if targetEnvironment(simulator)
        guard Bundle.developerModeEnabled else {
            return
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: UIWindow.didBecomeKeyNotification,
            object: nil
        )
        #endif
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        #if targetEnvironment(simulator)
        guard let window = notification.object as? UIWindow,
              window === self.keyWindow,
              tripleTapGestureRecognizer == nil else {
            return
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap))
        tapGesture.numberOfTapsRequired = 3
        tapGesture.cancelsTouchesInView = false
        window.addGestureRecognizer(tapGesture)
        tripleTapGestureRecognizer = tapGesture
        #endif
    }

    @objc private func handleTripleTap() {
        presentDeveloperTools()
    }

    // Shake gesture for real devices
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard Bundle.developerModeEnabled else {
            return
        }

        guard motion == .motionShake else { return }

        presentDeveloperTools()
    }

    private func presentDeveloperTools() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            presenter.presentIfNotDisplayed(
                with: appDelegate.appRootRouter,
                from: self.topmostViewController(onlyFullScreen: false)
            )
        }
    }

    deinit {
        #if targetEnvironment(simulator)
        NotificationCenter.default.removeObserver(self)
        #endif
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
