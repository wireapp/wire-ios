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
import WireFoundation
import WireSyncEngine

final class WireApplication: UIApplication {

    private let developerToolsPresenter = DeveloperToolsPresenter()
    private let shareDebugPresenter = ShareDebugReportPresenter()
    private var tripleTapGestureRecognizer: UITapGestureRecognizer?

    override init() {
        super.init()
        setupTripleTapGestureForSimulator()
    }

    deinit {
        #if targetEnvironment(simulator)
            NotificationCenter.default.removeObserver(self)
        #endif
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        handleShakeAction()
    }

    @objc
    private func handleShakeAction() {
        guard Bundle.developerModeEnabled else {
            presentDebugShareSheet()
            return
        }

        guard DeveloperFlag.shakeToReport.isOn else {
            presentDeveloperTools()
            return
        }

        guard shareDebugPresenter.isPresenting else {
            presentDebugShareSheet()
            return
        }

        shareDebugPresenter.dismiss { [weak self] in
            self?.presentDeveloperTools()
        }
    }

    private func presentDeveloperTools() {
        developerToolsPresenter.presentIfNotDisplayed(
            with: UIApplication.shared.sceneDelegates.first?.appRootRouter,
            from: self.topmostViewController(onlyFullScreen: false)
        )
    }

    private func presentDebugShareSheet() {
        shareDebugPresenter.present(from: topmostViewController(onlyFullScreen: false))
    }

    // MARK: - UITest support

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

    @objc
    private func windowDidBecomeKey(_ notification: Notification) {
        #if targetEnvironment(simulator)
            guard let window = notification.object as? UIWindow,
                  window === keyWindow,
                  tripleTapGestureRecognizer == nil else {
                return
            }

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleShakeAction))
            tapGesture.numberOfTapsRequired = 3
            tapGesture.cancelsTouchesInView = false
            window.addGestureRecognizer(tapGesture)
            tripleTapGestureRecognizer = tapGesture
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
