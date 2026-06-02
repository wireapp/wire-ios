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
import WireLogging

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        WireLogger.appDelegate.info("scene(_:willConnectTo:options:)")

        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = LaunchScreenViewController()
        window.makeKeyAndVisible()

        self.window = window


        setNavigationAppearance(isRightToLeft: window.isRightToLeft)

        (UIApplication.shared.delegate as? AppDelegate)?.sceneDidFinishConnecting(self)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        WireLogger.appDelegate.info("sceneDidDisconnect")

        
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        WireLogger.appDelegate.info("sceneDidBecomeActive")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        WireLogger.appDelegate.info("sceneWillResignActive")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        WireLogger.appDelegate.info("sceneWillEnterForeground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        WireLogger.appDelegate.info("sceneDidEnterBackground")
    }

    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        WireLogger.appDelegate.info("scene(_:openURLContexts:) count=\(urlContexts.count)")
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        WireLogger.appDelegate.info("scene(_:continue:) \(userActivity)")
    }

    // MARK: - Private

    private func setNavigationAppearance(isRightToLeft: Bool) {
        let backIndicator = UIImage(resource: isRightToLeft ? .forwardArrow : .backArrow)
        UINavigationBar.appearance().backIndicatorImage = backIndicator
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backIndicator
    }
}
