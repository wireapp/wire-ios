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

/// Adds an activity indicator subview to the provided `UIView` instance and disables user interaction.
@MainActor
public final class BlockingActivityIndicator {

    // MARK: - Properties

    private weak var view: UIView?

    // MARK: - Life Cycle

    public init(view: UIView) {
        self.view = view
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

    public func start() {
        view?.blockAndStartAnimating(blockingActivityIndicator: self)
    }

    public func stop() {
        view?.unblockAndStopAnimatingIfNeeded(blockingActivityIndicator: self)
    }
}

// MARK: - BlockingActivityIndicatorState

private struct BlockingActivityIndicatorState {
    var weakReferences = [WeakReference<BlockingActivityIndicator>]()
    private(set) var activityIndicatorView = UIActivityIndicatorView()
}

// MARK: - UIView + BlockingActivityIndicators

extension UIView {

    fileprivate func blockAndStartAnimating(blockingActivityIndicator reference: BlockingActivityIndicator) {

        var state = blockingActivityIndicatorState ?? .init()
        state.weakReferences = [.init(reference)] + state.weakReferences.filter { $0.reference != nil }
        blockingActivityIndicatorState = state

        // TODO: add subviews
    }

    fileprivate func unblockAndStopAnimatingIfNeeded(blockingActivityIndicator reference: BlockingActivityIndicator?) {

        guard var state = blockingActivityIndicatorState else { return }

        state.weakReferences = state.weakReferences.filter { $0.reference != nil && $0.reference !== reference }

        if state.weakReferences.isEmpty {
            // TODO: remove subviews and state
            blockingActivityIndicatorState = nil
        }
    }

    // TODO: consider declaring struct in order to only have one associatedObjectKey

    private var blockingActivityIndicatorState: BlockingActivityIndicatorState? {
        get { objc_getAssociatedObject(self, &stateKey) as? BlockingActivityIndicatorState }
        set { objc_setAssociatedObject(self, &stateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

private var stateKey = 0

// MARK: - WeakReference

// TODO: [WPB-8907] use the type `WeakReference` from WireSystem once WireSystem has become a Swift package.
private struct WeakReference<T: AnyObject> {

    weak var reference: T?

    init(_ reference: T) {
        self.init(reference: reference)
    }

    init(reference: T) {
        self.reference = reference
    }
}
