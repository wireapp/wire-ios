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
import WireDesign
import WireUtilities

// MARK: - NavigationController

final class NavigationController: UINavigationController {
    private lazy var pushTransition = NavigationTransition(operation: .push)
    private lazy var popTransition = NavigationTransition(operation: .pop)

    private var dismissGestureRecognizer: UIScreenEdgePanGestureRecognizer!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func setup() {
        delegate = self
        transitioningDelegate = self
    }

    var useDefaultPopGesture = false {
        didSet {
            interactivePopGestureRecognizer?.isEnabled = useDefaultPopGesture
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = SemanticColors.View.backgroundDefault
        useDefaultPopGesture = false
        navigationBar.tintColor = SemanticColors.Label.textDefault
        navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes()

        dismissGestureRecognizer = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(NavigationController.onEdgeSwipe(gestureRecognizer:))
        )
        dismissGestureRecognizer.edges = [.left]
        dismissGestureRecognizer.delegate = self
        view.addGestureRecognizer(dismissGestureRecognizer)
    }

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        viewControllers.forEach { $0.hideDefaultButtonTitle() }

        super.setViewControllers(viewControllers, animated: animated)
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        viewController.hideDefaultButtonTitle()

        super.pushViewController(viewController, animated: animated)
    }

    @objc
    func onEdgeSwipe(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        if gestureRecognizer.state == .recognized {
            popViewController(animated: true)
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        if let avoiding = viewController as? KeyboardAvoidingViewController {
            updateGesture(for: avoiding.viewController)
        } else {
            updateGesture(for: viewController)
        }
    }

    private func updateGesture(for viewController: UIViewController) {
        let translucentBackground = if let alpha = viewController.view.backgroundColor?.alpha, alpha < 1.0 {
            true
        } else {
            false
        }

        useDefaultPopGesture = !translucentBackground
    }

    // MARK: - status bar

    override var childForStatusBarStyle: UIViewController? {
        topViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        topViewController
    }
}

// MARK: UINavigationControllerDelegate

extension NavigationController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if useDefaultPopGesture {
            return nil
        }

        switch operation {
        case .push:
            return pushTransition
        case .pop:
            return popTransition
        default:
            fatalError()
        }
    }
}

// MARK: UIViewControllerTransitioningDelegate

extension NavigationController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        SwizzleTransition(direction: .vertical)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        SwizzleTransition(direction: .vertical)
    }
}

// MARK: UIGestureRecognizerDelegate

extension NavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if useDefaultPopGesture, gestureRecognizer == dismissGestureRecognizer {
            return false
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
