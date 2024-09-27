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

extension Notification.Name {
    static let SplitLayoutObservableDidChangeToLayoutSize = Notification
        .Name("SplitLayoutObservableDidChangeToLayoutSizeNotification")
}

// MARK: - SplitViewControllerTransition

enum SplitViewControllerTransition {
    case `default`
    case present
    case dismiss
}

// MARK: - SplitViewControllerLayoutSize

enum SplitViewControllerLayoutSize {
    case compact
    case regularPortrait
    case regularLandscape
}

// MARK: - SplitLayoutObservable

protocol SplitLayoutObservable: AnyObject {
    var layoutSize: SplitViewControllerLayoutSize { get }
    var leftViewControllerWidth: CGFloat { get }
}

// MARK: - SplitViewControllerDelegate

protocol SplitViewControllerDelegate: AnyObject {
    func splitViewControllerShouldMoveLeftViewController(_ splitViewController: SplitViewController) -> Bool
}

// MARK: - SplitViewController

final class SplitViewController: UIViewController, SplitLayoutObservable {
    // MARK: Lifecycle

    // MARK: - init

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    weak var delegate: SplitViewControllerDelegate?

    var rightViewController: UIViewController?

    var leftView = UIView(frame: UIScreen.main.bounds)
    var rightView: UIView = {
        let view = PlaceholderConversationView(frame: UIScreen.main.bounds)
        view.backgroundColor = SemanticColors.View.backgroundDefault

        return view
    }()

    // MARK: - SplitLayoutObservable

    var layoutSize: SplitViewControllerLayoutSize = .compact {
        didSet {
            guard oldValue != layoutSize else {
                return
            }

            NotificationCenter.default.post(
                name: Notification.Name.SplitLayoutObservableDidChangeToLayoutSize,
                object: self
            )
        }
    }

    var leftViewControllerWidth: CGFloat {
        leftViewWidthConstraint?.constant ?? 0
    }

    var openPercentage: CGFloat = 0 {
        didSet {
            updateRightAndLeftEdgeConstraints(openPercentage)

            setNeedsStatusBarAppearanceUpdate()
        }
    }

    var leftViewController: UIViewController? {
        get {
            internalLeftViewController
        }

        set {
            setLeftViewController(newValue)
        }
    }

    var isLeftViewControllerRevealed: Bool {
        get {
            internalLeftViewControllerRevealed
        }

        set {
            internalLeftViewControllerRevealed = newValue

            updateLeftViewController(animated: true)
        }
    }

    override var childForStatusBarStyle: UIViewController? {
        childViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        childViewController
    }

    // MARK: - animator

    var animatorForRightView: UIViewControllerAnimatedTransitioning {
        if layoutSize == .compact, isLeftViewControllerRevealed {
            // Right view is not visible so we should not animate.
            return CrossfadeTransition(duration: 0)
        } else if layoutSize == .regularLandscape {
            return SwizzleTransition(direction: .horizontal)
        }

        return CrossfadeTransition()
    }

    var isConversationViewVisible: Bool {
        layoutSize == .regularLandscape ||
            !isLeftViewControllerRevealed
    }

    // MARK: - update size

    /// return true if right view (mostly conversation screen) is fully visible
    var isRightViewControllerRevealed: Bool {
        switch layoutSize {
        case .compact, .regularPortrait:
            !isLeftViewControllerRevealed
        case .regularLandscape:
            true
        }
    }

    // MARK: - override

    override func viewDidLoad() {
        super.viewDidLoad()

        for item in [leftView, rightView] {
            item.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(item)
        }

        setupInitialConstraints()
        updateLayoutSize(for: traitCollection)
        updateConstraints(for: view.bounds.size)
        updateActiveConstraints()

        openPercentage = 1

        horizontalPanner.addTarget(self, action: #selector(onHorizontalPan(_:)))
        horizontalPanner.delegate = self
        view.addGestureRecognizer(horizontalPanner)
    }

    override func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        futureTraitCollection = newCollection
        updateLayoutSize(for: newCollection)

        super.willTransition(to: newCollection, with: coordinator)

        updateActiveConstraints()

        updateLeftViewVisibility()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        update(for: view.bounds.size)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        update(for: size)

        coordinator.animate(alongsideTransition: { _ in
        }, completion: { _ in
            self.updateLayoutSizeAndLeftViewVisibility()
        })
    }

    // MARK: - left and right view controllers

    func setLeftViewControllerRevealed(
        _ leftViewControllerRevealed: Bool,
        animated: Bool,
        completion: Completion? = nil
    ) {
        internalLeftViewControllerRevealed = leftViewControllerRevealed
        updateLeftViewController(animated: animated, completion: completion)
    }

    func setRightViewController(
        _ newRightViewController: UIViewController?,
        animated: Bool,
        completion: Completion? = nil
    ) {
        guard rightViewController != newRightViewController else {
            return
        }

        // To determine if self.rightViewController.presentedViewController is actually presented over it, or is it
        // presented over one of it's parents.
        if rightViewController?.presentedViewController?.presentingViewController == rightViewController {
            rightViewController?.dismiss(animated: false)
        }

        let transitionDidStart = transition(
            from: rightViewController,
            to: newRightViewController,
            containerView: rightView,
            animator: animatorForRightView,
            animated: animated,
            completion: completion
        )

        if transitionDidStart {
            rightViewController = newRightViewController
        }
    }

    func setLeftViewController(
        _ newLeftViewController: UIViewController?,
        animated: Bool = false,
        transition: SplitViewControllerTransition = .default,
        completion: Completion? = nil
    ) {
        guard leftViewController != newLeftViewController else {
            completion?()
            return
        }

        // without this line on iPad the text is displayed next to the tab item icon
        newLeftViewController.map { setOverrideTraitCollection(.init(horizontalSizeClass: .compact), forChild: $0) }

        let animator: UIViewControllerAnimatedTransitioning =
            if leftViewController == nil || newLeftViewController ==
            nil {
                CrossfadeTransition()
            } else if transition == .present {
                VerticalTransition(offset: 88)
            } else if transition == .dismiss {
                VerticalTransition(offset: -88)
            } else {
                CrossfadeTransition()
            }

        if self.transition(
            from: leftViewController,
            to: newLeftViewController,
            containerView: leftView,
            animator: animator,
            animated: animated,
            completion: completion
        ) {
            internalLeftViewController = newLeftViewController
        }
    }

    // MARK: - gesture

    @objc
    func onHorizontalPan(_ gestureRecognizer: UIPanGestureRecognizer?) {
        guard layoutSize != .regularLandscape,
              delegate?.splitViewControllerShouldMoveLeftViewController(self) == true,
              isConversationViewVisible,
              let gestureRecognizer else {
            return
        }

        var offset = gestureRecognizer.translation(in: view)

        switch gestureRecognizer.state {
        case .began:
            leftViewController?.beginAppearanceTransition(!isLeftViewControllerRevealed, animated: true)
            rightViewController?.beginAppearanceTransition(isLeftViewControllerRevealed, animated: true)
            leftView.isHidden = false

        case .changed:
            if let width = leftViewController?.view.bounds.size.width {
                if offset.x > 0, view.isRightToLeft {
                    offset.x = 0
                } else if offset.x < 0, !view.isRightToLeft {
                    offset.x = 0
                } else if abs(offset.x) > width {
                    offset.x = width
                }
                openPercentage = abs(offset.x) / width
                view.layoutIfNeeded()
            }

        case .cancelled,
             .ended:
            let isRevealing = gestureRecognizer.velocity(in: view).x > 0
            let didCompleteTransition = isRevealing != isLeftViewControllerRevealed

            setLeftViewControllerRevealed(isRevealing, animated: true) { [weak self] in
                if didCompleteTransition {
                    self?.leftViewController?.endAppearanceTransition()
                    self?.rightViewController?.endAppearanceTransition()
                }
            }

        default:
            break
        }
    }

    // MARK: Private

    private var internalLeftViewController: UIViewController?
    private var internalLeftViewControllerRevealed = true
    private var leftViewLeadingConstraint: NSLayoutConstraint!
    private var rightViewLeadingConstraint: NSLayoutConstraint!
    private var leftViewWidthConstraint: NSLayoutConstraint!
    private var rightViewWidthConstraint: NSLayoutConstraint!
    private var sideBySideConstraint: NSLayoutConstraint!
    private var pinLeftViewOffsetConstraint: NSLayoutConstraint!

    private var horizontalPanner = UIPanGestureRecognizer()

    private var futureTraitCollection: UITraitCollection?

    // MARK: - status bar

    private var childViewController: UIViewController? {
        openPercentage > 0 ? leftViewController : rightViewController
    }

    private var isiOSAppOnMac: Bool {
        ProcessInfo.processInfo.isiOSAppOnMac
    }

    private var constraintsActiveForCurrentLayout: [NSLayoutConstraint] {
        var constraints: Set<NSLayoutConstraint> = []

        if layoutSize == .regularLandscape {
            constraints.formUnion(Set([pinLeftViewOffsetConstraint, sideBySideConstraint]))
        }

        constraints.formUnion(Set([leftViewWidthConstraint]))

        return Array(constraints)
    }

    private var constraintsInactiveForCurrentLayout: [NSLayoutConstraint] {
        guard layoutSize != .regularLandscape else {
            return []
        }

        var constraints: Set<NSLayoutConstraint> = []
        constraints.formUnion(Set([pinLeftViewOffsetConstraint, sideBySideConstraint]))
        return Array(constraints)
    }

    /// update left view UI depends on isLeftViewControllerRevealed
    ///
    /// - Parameters:
    ///   - animated: animation enabled?
    ///   - completion: completion closure
    private func updateLeftViewController(animated: Bool, completion: Completion? = nil) {
        if animated {
            view.layoutIfNeeded()
        }
        leftView.isHidden = false

        resetOpenPercentage()
        if layoutSize != .regularLandscape {
            leftViewController?.beginAppearanceTransition(isLeftViewControllerRevealed, animated: animated)
            rightViewController?.beginAppearanceTransition(!isLeftViewControllerRevealed, animated: animated)
        }

        let completionBlock: Completion = {
            completion?()

            if self.openPercentage == 0,
               self.layoutSize != .regularLandscape,
               self.leftView.layer.presentation()?.frame == self.leftView
               .frame || (self.leftView.layer.presentation()?.frame == nil && !animated) {
                self.leftView.isHidden = true
            }
        }

        if animated {
            UIView.animate(easing: .easeOutExpo, duration: 0.55, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                if self.layoutSize != .regularLandscape {
                    self.leftViewController?.endAppearanceTransition()
                    self.rightViewController?.endAppearanceTransition()
                }
                completionBlock()
            })
        } else {
            completionBlock()
        }
    }

    /// Update layoutSize for the change of traitCollection and the current orientation
    ///
    /// - Parameters:
    ///   - traitCollection: the new traitCollection
    private func updateLayoutSize(for traitCollection: UITraitCollection) {
        switch (isiOSAppOnMac, traitCollection.horizontalSizeClass, UIWindow.interfaceOrientation?.isPortrait) {
        case (false, .regular, false), (true, _, true):
            layoutSize = .regularLandscape
        case (false, .regular, true):
            layoutSize = .regularPortrait
        default:
            layoutSize = .compact
        }
    }

    private func update(for size: CGSize) {
        updateLayoutSize(for: futureTraitCollection ?? traitCollection)

        updateConstraints(for: size)
        updateActiveConstraints()

        futureTraitCollection = nil

        // update right view constraits after size changes
        updateRightAndLeftEdgeConstraints(openPercentage)
    }

    private func updateLayoutSizeAndLeftViewVisibility() {
        updateLayoutSize(for: traitCollection)
        updateLeftViewVisibility()
    }

    private func updateLeftViewVisibility() {
        switch layoutSize {
        case .compact /* fallthrough */, .regularPortrait:
            leftView.isHidden = (openPercentage == 0)
        case .regularLandscape:
            leftView.isHidden = false
        }
    }

    private func transition(
        from fromViewController: UIViewController?,
        to toViewController: UIViewController?,
        containerView: UIView,
        animator: UIViewControllerAnimatedTransitioning?,
        animated: Bool,
        completion: Completion? = nil
    ) -> Bool {
        // Return if transition is done or already in progress
        if let toViewController, children.contains(toViewController) {
            return false
        }

        fromViewController?.willMove(toParent: nil)

        if let toViewController {
            toViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addChild(toViewController)
        } else {
            updateConstraints(for: view.bounds.size, willMoveToEmptyView: true)
        }

        let transitionContext = SplitViewControllerTransitionContext(
            from: fromViewController,
            to: toViewController,
            containerView: containerView
        )

        transitionContext.isInteractive = false
        transitionContext.isAnimated = animated
        transitionContext.completionBlock = { _ in
            fromViewController?.view.removeFromSuperview()
            fromViewController?.removeFromParent()
            toViewController?.didMove(toParent: self)
            completion?()
        }

        animator?.animateTransition(using: transitionContext)

        return true
    }

    private func resetOpenPercentage() {
        openPercentage = isLeftViewControllerRevealed ? 1 : 0
    }

    private func updateRightAndLeftEdgeConstraints(_ percentage: CGFloat) {
        rightViewLeadingConstraint.constant = leftViewWidthConstraint.constant * percentage
        leftViewLeadingConstraint.constant = 64 * (1 - percentage)
    }

    // MARK: - constraints

    private func setupInitialConstraints() {
        leftViewLeadingConstraint = leftView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        leftViewLeadingConstraint.priority = UILayoutPriority.defaultHigh
        rightViewLeadingConstraint = rightView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        rightViewLeadingConstraint.priority = UILayoutPriority.defaultHigh

        leftViewWidthConstraint = leftView.widthAnchor.constraint(equalToConstant: 0)
        rightViewWidthConstraint = rightView.widthAnchor.constraint(equalToConstant: 0)

        pinLeftViewOffsetConstraint = leftView.leftAnchor.constraint(equalTo: view.leftAnchor)
        sideBySideConstraint = rightView.leftAnchor.constraint(equalTo: leftView.rightAnchor)
        sideBySideConstraint.isActive = false

        let constraints: [NSLayoutConstraint] =
            [
                leftView.topAnchor.constraint(equalTo: view.topAnchor),
                leftView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                rightView.topAnchor.constraint(equalTo: view.topAnchor),
                rightView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                leftViewLeadingConstraint,
                rightViewLeadingConstraint,
                leftViewWidthConstraint,
                rightViewWidthConstraint,
                pinLeftViewOffsetConstraint,
            ]

        NSLayoutConstraint.activate(constraints)
    }

    private func updateActiveConstraints() {
        NSLayoutConstraint.deactivate(constraintsInactiveForCurrentLayout)
        NSLayoutConstraint.activate(constraintsActiveForCurrentLayout)
    }

    private func leftViewMinWidth(size: CGSize) -> CGFloat {
        min(size.width * 0.43, CGFloat.SplitView.LeftViewWidth)
    }

    private func updateConstraints(for size: CGSize, willMoveToEmptyView toEmptyView: Bool = false) {
        let isRightViewEmpty: Bool = rightViewController == nil || toEmptyView

        switch (layoutSize, isRightViewEmpty) {
        case (.compact, _):
            leftViewWidthConstraint.constant = size.width
            rightViewWidthConstraint.constant = size.width

        case (.regularLandscape, _),
             (.regularPortrait, true):
            leftViewWidthConstraint.constant = leftViewMinWidth(size: size)
            rightViewWidthConstraint.constant = size.width - leftViewWidthConstraint.constant

        case (.regularPortrait, false):
            leftViewWidthConstraint.constant = leftViewMinWidth(size: size)
            rightViewWidthConstraint.constant = size.width
        }
    }
}

// MARK: UIGestureRecognizerDelegate

extension SplitViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        if layoutSize == .regularLandscape {
            return false
        }

        if let delegate, !delegate.splitViewControllerShouldMoveLeftViewController(self) {
            return false
        }

        if isLeftViewControllerRevealed, !isIPadRegular() {
            return false
        }

        return true
    }
}
