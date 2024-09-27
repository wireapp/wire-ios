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

final class BlurEffectTransition: NSObject, UIViewControllerAnimatedTransitioning {
    // MARK: Lifecycle

    init(visualEffectView: UIVisualEffectView, crossfadingViews: [UIView], reverse: Bool) {
        self.reverse = reverse
        self.visualEffectView = visualEffectView
        self.crossfadingViews = crossfadingViews

        super.init()
    }

    // MARK: Internal

    let reverse: Bool
    let visualEffectView: UIVisualEffectView
    let crossfadingViews: [UIView]

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.35
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let toView = transitionContext.view(forKey: UITransitionContextViewKey.to),
           let toViewController = transitionContext.viewController(forKey: .to) {
            toView.frame = transitionContext.finalFrame(for: toViewController)
            transitionContext.containerView.addSubview(toView)
        }

        if !transitionContext.isAnimated {
            transitionContext.completeTransition(true)
            return
        }

        transitionContext.view(forKey: UITransitionContextViewKey.to)?.layoutIfNeeded()

        let visualEffect = visualEffectView.effect

        if reverse {
            UIView.animate(withDuration: 0.35, animations: {
                for view in self.crossfadingViews {
                    view.alpha = 0
                }

                self.visualEffectView.effect = nil
            }, completion: { didComplete in
                self.visualEffectView.effect = visualEffect
                transitionContext.completeTransition(didComplete)
            })
        } else {
            visualEffectView.effect = nil
            for view in crossfadingViews {
                view.alpha = 0
            }

            UIView.animate(withDuration: 0.35, animations: {
                for view in self.crossfadingViews {
                    view.alpha = 1
                }

                self.visualEffectView.effect = visualEffect
            }, completion: { didComplete in
                transitionContext.completeTransition(didComplete)
            })
        }
    }
}
