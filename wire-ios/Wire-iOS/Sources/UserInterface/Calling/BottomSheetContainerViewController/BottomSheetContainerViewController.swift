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

class BottomSheetContainerViewController: UIViewController {

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

    // MARK: - Variables

    private let viewModel = BottomSheetContainerViewModel()
    private var topConstraint = NSLayoutConstraint()
    var state: BottomSheetState = .initial {
        didSet {
            didChangeState()
        }
    }

    private var visibleControllerBottomConstraint: NSLayoutConstraint!
    private var bottomViewHeightConstraint: NSLayoutConstraint!

    private(set) var contentViewController: UIViewController
    private(set) var bottomSheetViewController: UIViewController

    var configuration: BottomSheetConfiguration {
        didSet {
            let constraintState = viewModel.configurationConstraintState(for: configuration)
            visibleControllerBottomConstraint.constant = constraintState.visibleControllerBottomConstant
            bottomViewHeightConstraint.constant = constraintState.bottomViewHeightConstant
            view.setNeedsLayout()
        }
    }

    lazy var panGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer()
        pan.delegate = self
        pan.addTarget(self, action: #selector(handlePan))
        return pan
    }()

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

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
            topConstraint
        ])
        bottomSheetViewController.didMove(toParent: self)
    }

    func addContentViewController(contentViewController: UIViewController) {
        self.contentViewController = contentViewController
        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        visibleControllerBottomConstraint = contentViewController.view.bottomAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: -configuration.initialOffset
        )

        NSLayoutConstraint.activate([
            contentViewController.view.leftAnchor
                .constraint(equalTo: view.leftAnchor),
            contentViewController.view.rightAnchor
                .constraint(equalTo: view.rightAnchor),
            contentViewController.view.topAnchor
                .constraint(equalTo: view.topAnchor).withPriority(.defaultLow),
            visibleControllerBottomConstraint
        ])
        contentViewController.didMove(toParent: self)

    }

    func didChangeState() {} // for overriding

    // MARK: - Bottom Sheet Actions

    func showBottomSheet(animated: Bool = true) {
        topConstraint.constant = viewModel.topConstraintConstant(for: .full, configuration: configuration)

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
        topConstraint.constant = viewModel.topConstraintConstant(for: .initial, configuration: configuration)

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

        switch sender.state {
        case .began, .changed:
            switch viewModel.panChangeDecision(
                state: state,
                translationY: translation.y,
                configuration: configuration
            ) {
            case .none:
                return
            case let .update(topConstraintConstant):
                topConstraint.constant = topConstraintConstant
                view.layoutIfNeeded()
            case .show:
                showBottomSheet()
                return
            }
            let percent = viewModel.offsetPercentage(
                topConstraintConstant: topConstraint.constant,
                configuration: configuration
            )
            bottomSheetChangedOffset(fullHeightPercentage: percent)
        case .ended:
            apply(
                snapDecision: viewModel.panEndSnapDecision(
                    state: state,
                    translationY: translation.y,
                    velocityY: velocity.y,
                    configuration: configuration
                )
            )
        case .failed:
            apply(snapDecision: viewModel.panFailedSnapDecision(state: state))
        default: break
        }
    }

    func bottomSheetChangedOffset(fullHeightPercentage: CGFloat) {}

    private func apply(snapDecision: BottomSheetContainerViewModel.SnapDecision) {
        switch snapDecision {
        case .show:
            showBottomSheet()
        case .hide:
            hideBottomSheet()
        }
    }
}

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
