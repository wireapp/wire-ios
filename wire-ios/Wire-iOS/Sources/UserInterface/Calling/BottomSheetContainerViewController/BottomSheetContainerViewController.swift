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

// MARK: - BottomSheetContainerViewController

class BottomSheetContainerViewController: UIViewController {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(
        contentViewController: UIViewController,
        bottomSheetViewController: UIViewController,
        bottomSheetConfiguration: BottomSheetConfiguration
    ) {
        self.contentViewController = contentViewController
        self.bottomSheetViewController = bottomSheetViewController
        self.configuration = bottomSheetConfiguration

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: Internal

    // MARK: - Configuration

    struct BottomSheetConfiguration: Equatable {
        let height: CGFloat
        let initialOffset: CGFloat
    }

    // MARK: - State

    enum BottomSheetState {
        case initial
        case full
    }

    private(set) var contentViewController: UIViewController
    private(set) var bottomSheetViewController: UIViewController

    lazy var panGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer()
        pan.delegate = self
        pan.addTarget(self, action: #selector(handlePan))
        return pan
    }()

    var state: BottomSheetState = .initial {
        didSet {
            didChangeState()
        }
    }

    var configuration: BottomSheetConfiguration {
        didSet {
            visibleControllerBottomConstraint.constant = -configuration.initialOffset
            bottomViewHeightConstraint.constant = configuration.height
            view.setNeedsLayout()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func addContentViewController(contentViewController: UIViewController) {
        self.contentViewController = contentViewController
        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        visibleControllerBottomConstraint = contentViewController.view.bottomAnchor
            .constraint(
                equalTo: view.bottomAnchor,
                constant: -configuration
                    .initialOffset
            )

        NSLayoutConstraint.activate([
            contentViewController.view.leftAnchor
                .constraint(equalTo: view.leftAnchor),
            contentViewController.view.rightAnchor
                .constraint(equalTo: view.rightAnchor),
            contentViewController.view.topAnchor
                .constraint(equalTo: view.topAnchor).withPriority(.defaultLow),
            visibleControllerBottomConstraint,
        ])
        contentViewController.didMove(toParent: self)
    }

    func didChangeState() {} // for overriding

    // MARK: - Bottom Sheet Actions

    func showBottomSheet(animated: Bool = true) {
        topConstraint.constant = -configuration.height

        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
                self.bottomSheetChangedOffset(fullHeightPercentage: 1.0)
            }, completion: { _ in
                self.state = .full
            })
        } else {
            view.layoutIfNeeded()
            state = .full
            bottomSheetChangedOffset(fullHeightPercentage: 1.0)
        }
    }

    func hideBottomSheet(animated: Bool = true) {
        topConstraint.constant = -configuration.initialOffset

        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5,
                options: [.curveEaseOut],
                animations: {
                    self.view.layoutIfNeeded()
                    self.bottomSheetChangedOffset(fullHeightPercentage: 0.0)
                },
                completion: { _ in
                    self.state = .initial
                }
            )
        } else {
            view.layoutIfNeeded()
            state = .initial
            bottomSheetChangedOffset(fullHeightPercentage: 0.0)
        }
    }

    @objc
    func handlePan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: bottomSheetViewController.view)
        let velocity = sender.velocity(in: bottomSheetViewController.view)

        let yTranslationMagnitude = translation.y.magnitude

        switch sender.state {
        case .began, .changed:
            if state == .full {
                guard translation.y > 0 else { return }
                topConstraint.constant = -(configuration.height - yTranslationMagnitude)
                view.layoutIfNeeded()
            } else {
                let newConstant = -(configuration.initialOffset + yTranslationMagnitude)
                guard translation.y < 0 else { return }
                guard newConstant.magnitude < configuration.height else {
                    showBottomSheet()
                    return
                }
                topConstraint.constant = newConstant
                view.layoutIfNeeded()
            }
            let percent = (-topConstraint.constant - configuration.initialOffset) /
                (configuration.height - configuration.initialOffset)
            bottomSheetChangedOffset(fullHeightPercentage: percent)

        case .ended:
            if state == .full {
                if velocity.y < 0 {
                    showBottomSheet()
                } else if yTranslationMagnitude >= configuration.height / 2 || velocity.y > 1000 {
                    hideBottomSheet()
                } else {
                    showBottomSheet()
                }
            } else {
                if yTranslationMagnitude >= configuration.height / 2 || velocity.y < -1000 {
                    showBottomSheet()
                } else {
                    hideBottomSheet()
                }
            }

        case .failed:
            if state == .full {
                showBottomSheet()
            } else {
                hideBottomSheet()
            }

        default: break
        }
    }

    func bottomSheetChangedOffset(fullHeightPercentage: CGFloat) {}

    // MARK: Private

    // MARK: - Variables

    private var topConstraint = NSLayoutConstraint()
    private var visibleControllerBottomConstraint: NSLayoutConstraint!
    private var bottomViewHeightConstraint: NSLayoutConstraint!

    private func setupUI() {
        addContentViewController(contentViewController: contentViewController)
        addBottomSheetViewController(bottomSheetViewController: bottomSheetViewController)
    }

    private func addBottomSheetViewController(bottomSheetViewController: UIViewController) {
        addChild(bottomSheetViewController)
        view.addSubview(bottomSheetViewController.view)

        bottomSheetViewController.view.addGestureRecognizer(panGesture)
        bottomSheetViewController.view.translatesAutoresizingMaskIntoConstraints = false

        topConstraint = bottomSheetViewController.view.topAnchor
            .constraint(
                equalTo: view.bottomAnchor,
                constant: -configuration.initialOffset
            )

        bottomViewHeightConstraint = bottomSheetViewController.view.heightAnchor
            .constraint(equalToConstant: configuration.height)
        NSLayoutConstraint.activate([
            bottomViewHeightConstraint,
            bottomSheetViewController.view.leftAnchor
                .constraint(equalTo: view.leftAnchor),
            bottomSheetViewController.view.rightAnchor
                .constraint(equalTo: view.rightAnchor),
            topConstraint,
        ])
        bottomSheetViewController.didMove(toParent: self)
    }
}

// MARK: UIGestureRecognizerDelegate

extension BottomSheetContainerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let otherGestureView = otherGestureRecognizer.view as? UIScrollView,
           otherGestureView.contentOffset.y > 0.0 {
            return false
        }
        return true
    }
}

// MARK: BottomSheetScrollingDelegate

extension BottomSheetContainerViewController: BottomSheetScrollingDelegate {
    var isBottomSheetExpanded: Bool {
        state == .full
    }

    func toggleBottomSheetVisibility() {
        switch state {
        case .full:
            hideBottomSheet(animated: false)
        case .initial:
            showBottomSheet(animated: false)
        }
    }
}
