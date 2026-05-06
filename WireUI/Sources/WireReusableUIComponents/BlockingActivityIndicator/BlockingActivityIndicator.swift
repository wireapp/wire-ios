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

import SwiftUI
import WireFoundation

/// Adds an activity indicator subview to the provided `UIView` instance and disables user interaction.
public final class BlockingActivityIndicator {

    public enum Style {
        /// Full-screen dimmed overlay with a white spinner centered on it.
        case fullScreen
        /// Full-screen dimmed overlay with a centered white card containing a dark spinner and text.
        case card
    }

    // MARK: - Private Properties

    private weak var view: UIView?
    private let accessibilityAnnouncement: String?
    private let style: Style

    // MARK: - Life Cycle

    public init(
        view: UIView,
        accessibilityAnnouncement: String?,
        style: Style = .fullScreen
    ) {
        self.view = view
        self.accessibilityAnnouncement = accessibilityAnnouncement
        self.style = style
    }

    deinit {
        let view = view
        Task {
            await MainActor.run { [weak view] in
                view?.unblockAndStopAnimatingIfNeeded(blockingActivityIndicator: nil)
            }
        }
    }

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
        view?.blockAndStartAnimating(blockingActivityIndicator: self, text: text, style: style)
    }

    @MainActor
    public func stop() {
        view?.unblockAndStopAnimatingIfNeeded(blockingActivityIndicator: self)
    }
}

// MARK: - BlockingActivityIndicatorState

private struct BlockingActivityIndicatorState {
    var weakReferences = [WeakReference<BlockingActivityIndicator>]()
    private(set) var activityIndicatorView = ProgressSpinner()
    var blockingView: UIView?
}

// MARK: - UIView + BlockingActivityIndicators

private extension UIView {

    func blockAndStartAnimating(
        blockingActivityIndicator reference: BlockingActivityIndicator,
        text: String,
        style: BlockingActivityIndicator.Style
    ) {
        var state: BlockingActivityIndicatorState! = blockingActivityIndicatorState

        // set up subviews
        if state == nil {
            state = .init()

            // dim overlay which swallows touch events
            let blockingView = UIView()
            state.blockingView = blockingView
            blockingView.backgroundColor = .black.withAlphaComponent(0.5)
            blockingView.isUserInteractionEnabled = true
            blockingView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(blockingView)

            NSLayoutConstraint.activate([
                blockingView.leadingAnchor.constraint(equalTo: leadingAnchor),
                blockingView.topAnchor.constraint(equalTo: topAnchor),
                trailingAnchor.constraint(equalTo: blockingView.trailingAnchor),
                bottomAnchor.constraint(equalTo: blockingView.bottomAnchor)
            ])

            state.activityIndicatorView.text = text
            state.activityIndicatorView.isAnimating = true
            state.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false

            switch style {
            case .fullScreen:
                state.activityIndicatorView.color = .white
                blockingView.addSubview(state.activityIndicatorView)
                NSLayoutConstraint.activate([
                    state.activityIndicatorView.centerXAnchor.constraint(equalTo: blockingView.centerXAnchor),
                    state.activityIndicatorView.centerYAnchor.constraint(equalTo: blockingView.centerYAnchor)
                ])

            case .card:
                state.activityIndicatorView.color = .label
                state.activityIndicatorView.textColor = .label

                let card = UIView()
                card.backgroundColor = .systemBackground
                card.layer.cornerRadius = 16
                card.layer.masksToBounds = true
                card.translatesAutoresizingMaskIntoConstraints = false
                blockingView.addSubview(card)
                card.addSubview(state.activityIndicatorView)

                // Card prefers 65% of the overlay width (wide enough for label text on iPhone)
                // but is capped at 300pt so it stays compact on iPad.
                // Spinner uses equalTo horizontal margins so it fills the card — this overrides
                // ProgressSpinner.intrinsicContentSize (32pt) which ignores the label width.
                let preferredWidth = card.widthAnchor.constraint(equalTo: blockingView.widthAnchor, multiplier: 0.65)
                preferredWidth.priority = .defaultHigh
                NSLayoutConstraint.activate([
                    card.centerXAnchor.constraint(equalTo: blockingView.centerXAnchor),
                    card.centerYAnchor.constraint(equalTo: blockingView.centerYAnchor),
                    preferredWidth,
                    card.widthAnchor.constraint(lessThanOrEqualToConstant: 300),

                    state.activityIndicatorView.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
                    state.activityIndicatorView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
                    card.trailingAnchor.constraint(equalTo: state.activityIndicatorView.trailingAnchor, constant: 24),
                    card.bottomAnchor.constraint(equalTo: state.activityIndicatorView.bottomAnchor, constant: 24)
                ])
            }
        }

        // add the reference into the `weakReferences` array
        state.weakReferences = state.weakReferences.filter { $0.reference != nil } + [.init(reference)]
        blockingActivityIndicatorState = state
    }

    func unblockAndStopAnimatingIfNeeded(blockingActivityIndicator reference: BlockingActivityIndicator?) {
        guard var state = blockingActivityIndicatorState else { return }

        state.weakReferences = state.weakReferences.filter { $0.reference != nil && $0.reference !== reference }
        if state.weakReferences.isEmpty {
            state.blockingView?.removeFromSuperview()
            blockingActivityIndicatorState = nil
        }
    }

    private var blockingActivityIndicatorState: BlockingActivityIndicatorState? {
        get { objc_getAssociatedObject(self, &stateKey) as? BlockingActivityIndicatorState }
        set { objc_setAssociatedObject(self, &stateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

@MainActor private var stateKey = 0

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
            targetView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 2 / 3)
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
                UIButton(primaryAction: .init(title: "Stop") { _ in blockingActivityIndicator.stop() })
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
