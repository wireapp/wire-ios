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

final class RootViewController: UIViewController {

    // MARK: - Private Property

    private var childViewController: UIViewController?

    // MARK: - Status Bar / Supported Orientations

    override var shouldAutorotate: Bool {
        NSLog("RootViewController >#@<# %@", "shouldAutorotate: \(true)")
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let presentedViewController,
           presentedViewController is ModalPresentationViewController,
           !presentedViewController.isBeingDismissed {
            NSLog("RootViewController >#@<# %@", "supportedInterfaceOrientations: \(presentedViewController.supportedInterfaceOrientations)")
            return presentedViewController.supportedInterfaceOrientations
        }
        NSLog("RootViewController >#@<# %@", "supportedInterfaceOrientations: \(wr_supportedInterfaceOrientations)")
        return wr_supportedInterfaceOrientations
    }

    override var childForStatusBarStyle: UIViewController? {
        NSLog("RootViewController >#@<# %@", "childForStatusBarStyle: \(childViewController)")
        return childViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        NSLog("RootViewController >#@<# %@", "childForStatusBarHidden: \(childViewController)")
        return childViewController
    }

    func set(
        childViewController newViewController: UIViewController,
        animated: Bool = false,
        completion: (() -> Void)?
    ) {
        NSLog("RootViewController >#@<# %@", "set(childViewController: \(newViewController), animated: \(animated))")

        if let previousViewController = childViewController {
            transition(
                from: previousViewController,
                to: newViewController,
                animated: animated,
                completion: completion)
        } else {
            contain(newViewController, completion: completion)
        }

        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }

    private func contain(_ newViewController: UIViewController, completion: (() -> Void)?) {
        NSLog("RootViewController >#@<# %@", "contain: \(newViewController)")
        UIView.performWithoutAnimation {
            add(newViewController, to: view)
            childViewController = newViewController
            completion?()
        }
    }

    private func transition(
        from fromViewController: UIViewController,
        to toViewController: UIViewController,
        animated: Bool = false,
        completion: (() -> Void)?
    ) {
        NSLog("RootViewController >#@<# %@", "transition(from: \(fromViewController) to: \(toViewController) animated: \(animated)")

        let animationGroup = DispatchGroup()

        if fromViewController.presentedViewController != nil {
            animationGroup.enter()
            fromViewController.dismiss(animated: animated) {
                animationGroup.leave()
            }
        }

        fromViewController.willMove(toParent: nil)
        addChild(toViewController)

        toViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        toViewController.view.frame = fromViewController.view.bounds

        animationGroup.enter()
        transition(
            from: fromViewController,
            to: toViewController,
            duration: animated ? 0.5 : 0,
            options: .transitionCrossDissolve,
            animations: {
                self.view.bringSubviewToFront(fromViewController.view)
                fromViewController.view.alpha = 0
            }, completion: { _ in
                fromViewController.removeFromParent()
                toViewController.didMove(toParent: self)
                animationGroup.leave()
            })

        childViewController = toViewController

        animationGroup.notify(queue: .main) {
            completion?()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        NSLog("RootViewController >#@<# %@", "viewWillTransition(to: \(size), coordinator: \(coordinator)")
        super.viewWillTransition(to: size, with: coordinator)

        guard let appRouter = (UIApplication.shared.delegate as? AppDelegate)?.appRootRouter else {
            return
        }

        coordinator.animate(alongsideTransition: nil) { _ in
            appRouter.updateOverlayWindowFrame(size: size)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        NSLog("RootViewController >#@<# %@", "traitCollectionDidChange(previousTraitCollection: \(previousTraitCollection)")
        super.traitCollectionDidChange(previousTraitCollection)

        // Do not refresh for iOS 13+ when the app is in background.
        // Go to home screen may trigger `traitCollectionDidChange` twice.
        if UIApplication.shared.applicationState == .background {
            return
        }

        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            NotificationCenter.default.post(name: .SettingsColorSchemeChanged, object: nil)
        }
    }
}
