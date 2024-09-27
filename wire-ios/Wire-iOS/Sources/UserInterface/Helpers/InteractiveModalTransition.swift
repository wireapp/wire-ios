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

// MARK: - ModalPresentationConfiguration

struct ModalPresentationConfiguration {
    let alpha: CGFloat
    let duration: TimeInterval
}

extension UIViewControllerContextTransitioning {
    private func complete(_: Bool) {
        completeTransition(!transitionWasCancelled)
    }
}

// MARK: - ModalInteractionController

private final class ModalInteractionController: UIPercentDrivenInteractiveTransition {
    var interactionInProgress = false
    private var shouldCompleteTransition = false
    private weak var presentationViewController: ModalPresentationViewController!

    func setupWith(viewController: ModalPresentationViewController) {
        presentationViewController = viewController
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        panGestureRecognizer.maximumNumberOfTouches = 1
        viewController.view.addGestureRecognizer(panGestureRecognizer)
    }

    @objc
    private func didPan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view!.superview!)
        var progress = (translation.y / presentationViewController.viewController.view.bounds.height)
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))

        switch sender.state {
        case .began:
            interactionInProgress = true
            presentationViewController.dismiss(animated: true)

        case .changed:
            shouldCompleteTransition = progress > 0.2
            update(progress)

        case .cancelled:
            interactionInProgress = false
            cancel()

        case .ended:
            interactionInProgress = false
            if !shouldCompleteTransition {
                cancel()
            } else {
                finish()
            }

        default: break
        }
    }
}

// MARK: - ModalPresentationViewController

final class ModalPresentationViewController: UIViewController, UIViewControllerTransitioningDelegate {
    fileprivate unowned let viewController: UIViewController
    fileprivate let dimView = UIView()

    private let interactionController = ModalInteractionController()
    private let configuration: ModalPresentationConfiguration

    init(
        viewController: UIViewController,
        configuration: ModalPresentationConfiguration = .init(alpha: 0.3, duration: 0.3),
        enableDismissOnPan: Bool = true
    ) {
        self.viewController = viewController
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        setupViews(with: viewController, enableDismissOnPan: enableDismissOnPan)
        createConstraints()
        modalPresentationCapturesStatusBarAppearance = true
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var childForStatusBarStyle: UIViewController? {
        viewController
    }

    override var childForStatusBarHidden: UIViewController? {
        viewController
    }

    private func setupViews(with viewController: UIViewController, enableDismissOnPan: Bool) {
        transitioningDelegate = self
        if enableDismissOnPan {
            interactionController.setupWith(viewController: self)
        }
        modalPresentationStyle = .overFullScreen
        view.addSubview(dimView)
        dimView.backgroundColor = .clear
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapDimView)))
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }

    private func createConstraints() {
        if let childViewControllerView = viewController.view {
            [childViewControllerView, dimView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
            NSLayoutConstraint.activate([
                childViewControllerView.topAnchor.constraint(equalTo: view.topAnchor),
                childViewControllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                childViewControllerView.leftAnchor.constraint(equalTo: view.leftAnchor),
                childViewControllerView.rightAnchor.constraint(equalTo: view.rightAnchor),
                dimView.topAnchor.constraint(equalTo: view.topAnchor),
                dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                dimView.leftAnchor.constraint(equalTo: view.leftAnchor),
                dimView.rightAnchor.constraint(equalTo: view.rightAnchor),
            ])
        }
    }

    @objc
    private func didTapDimView(_: UITapGestureRecognizer) {
        dismiss(animated: true)
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        nil
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning? {
        interactionController.interactionInProgress ? interactionController : nil
    }
}
