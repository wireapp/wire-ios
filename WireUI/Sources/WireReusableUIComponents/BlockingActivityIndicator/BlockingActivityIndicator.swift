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

import SwiftUI
import WireFoundation

// MARK: - BlockingActivityIndicator

/// Adds an activity indicator subview to the provided `UIView` instance and disables user interaction.
public final class BlockingActivityIndicator {
    // MARK: Lifecycle

    public init(
        view: UIView,
        accessibilityAnnouncement: String?
    ) {
        self.view = view
        self.accessibilityAnnouncement = accessibilityAnnouncement
    }

    deinit {
        let view = view
        Task {
            await MainActor.run { [weak view] in
                view?.unblockAndStopAnimatingIfNeeded(blockingActivityIndicator: nil)
            }
        }
    }

    // MARK: Public

    // MARK: - Methods

    @MainActor
    public func setIsActive(_ isActive: Bool) {
        if isActive {
            start()
        } else {
            stop()
        }
    }

    @MainActor
    public func start(text: String = "") {
        if let accessibilityAnnouncement {
            UIAccessibility.post(notification: .announcement, argument: accessibilityAnnouncement)
        }
        view?.blockAndStartAnimating(blockingActivityIndicator: self, text: text)
    }

    @MainActor
    public func stop() {
        view?.unblockAndStopAnimatingIfNeeded(blockingActivityIndicator: self)
    }

    // MARK: Private

    // MARK: - Private Properties

    private weak var view: UIView?
    private let accessibilityAnnouncement: String?
}

// MARK: - BlockingActivityIndicatorState

private struct BlockingActivityIndicatorState {
    var weakReferences = [WeakReference<BlockingActivityIndicator>]()
    private(set) var activityIndicatorView = ProgressSpinner()
}

// MARK: - UIView + BlockingActivityIndicators

extension UIView {
    fileprivate func blockAndStartAnimating(
        blockingActivityIndicator reference: BlockingActivityIndicator,
        text: String
    ) {
        var state: BlockingActivityIndicatorState! = blockingActivityIndicatorState

        // set up subviews
        if state == nil {
            state = .init()

            // view with dimmed background which swallows touch events
            let blockingView = UIView()
            blockingView.backgroundColor = .black.withAlphaComponent(0.5)
            blockingView.isUserInteractionEnabled = true
            blockingView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(blockingView)

            // activity indicator view
            state.activityIndicatorView.color = .white
            state.activityIndicatorView.text = text
            state.activityIndicatorView.isAnimating = true
            state.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
            blockingView.addSubview(state.activityIndicatorView)

            NSLayoutConstraint.activate([
                blockingView.leadingAnchor.constraint(equalTo: leadingAnchor),
                blockingView.topAnchor.constraint(equalTo: topAnchor),
                trailingAnchor.constraint(equalTo: blockingView.trailingAnchor),
                bottomAnchor.constraint(equalTo: blockingView.bottomAnchor),

                state.activityIndicatorView.centerXAnchor.constraint(equalTo: blockingView.centerXAnchor),
                state.activityIndicatorView.centerYAnchor.constraint(equalTo: blockingView.centerYAnchor),
            ])
        }

        // add the reference into the `weakReferences` array
        state.weakReferences = state.weakReferences.filter { $0.reference != nil } + [.init(reference)]
        blockingActivityIndicatorState = state
    }

    fileprivate func unblockAndStopAnimatingIfNeeded(blockingActivityIndicator reference: BlockingActivityIndicator?) {
        guard var state = blockingActivityIndicatorState else { return }

        state.weakReferences = state.weakReferences.filter { $0.reference != nil && $0.reference !== reference }
        if state.weakReferences.isEmpty {
            state.activityIndicatorView.superview!.removeFromSuperview()
            blockingActivityIndicatorState = nil
        }
    }

    private var blockingActivityIndicatorState: BlockingActivityIndicatorState? {
        get { objc_getAssociatedObject(self, &stateKey) as? BlockingActivityIndicatorState }
        set { objc_setAssociatedObject(self, &stateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

private var stateKey = 0

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    {
        let contentView = UIView()

        let targetView = UIView()
        targetView.backgroundColor = .systemGray6
        targetView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(targetView)
        NSLayoutConstraint.activate([
            targetView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            targetView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: targetView.trailingAnchor),
            targetView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 2 / 3),
        ])

        let testButtonAction = UIAction(title: "Tap here!") {
            let button = $0.sender as! UIButton
            let newTitle = "\((Int(button.title(for: .normal)!) ?? 0) + 1)"
            button.setTitle(newTitle, for: .normal)
        }
        let testButton = UIButton(primaryAction: testButtonAction)
        testButton.titleLabel?.font = .systemFont(ofSize: 40)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        targetView.addSubview(testButton)
        testButton.centerXAnchor.constraint(equalTo: targetView.centerXAnchor).isActive = true
        testButton.centerYAnchor.constraint(equalTo: targetView.centerYAnchor, constant: 100).isActive = true

        let blockingActivityIndicator = BlockingActivityIndicator(view: targetView, accessibilityAnnouncement: .none)

        let controlsView = UIStackView(
            arrangedSubviews: [
                UIButton(primaryAction: .init(title: "Start") { _ in blockingActivityIndicator.start() }),
                UIButton(primaryAction: .init(title: "Stop") { _ in blockingActivityIndicator.stop() }),
            ]
        )
        controlsView.spacing = 24
        controlsView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(controlsView)
        controlsView.topAnchor.constraint(equalToSystemSpacingBelow: targetView.bottomAnchor, multiplier: 2)
            .isActive = true
        controlsView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true

        return contentView
    }()
}
