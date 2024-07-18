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

    private weak var view: UIView?
    private weak var activityIndicatorView: UIActivityIndicatorView? // TODO: move to extension

    var isAnimating: Bool {
        get { fatalError() }
        set { fatalError() }
    }

    public init(view: UIView) {
        self.view = view
    }

    deinit {
        let view = view
        Task {
            await MainActor.run { [weak view] in
                view?.cleanUpBlockingActivityIndicators()
            }
        }
    }

    public func startAnimating() {
        UIActivityIndicatorView().isAnimating
    }

    public func stopAnimating() {
        //
    }
}

// MARK: - UIView + BlockingActivityIndicators

extension UIView {

    // TODO: consider declaring struct in order to only have one associatedObjectKey

    private var blockingActivityIndicators: [WeakReference<BlockingActivityIndicator>] {
        get { objc_getAssociatedObject(self, &associatedObjectKey) as? [WeakReference<BlockingActivityIndicator>] ?? [] }
        set { objc_setAssociatedObject(self, &associatedObjectKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    // TODO: rename and add subview, set userinteractionenabled etc.
    fileprivate func addBlockingActivityIndicator(_ blockingActivityIndicator: BlockingActivityIndicator) {
        blockingActivityIndicators += [.init(reference: blockingActivityIndicator)]
    }

    // TODO: also remove subviews
    /// Removes all references to `BlockingActivityIndicator` which have been destroyed.
    /// - Returns: `true` if no more reference exists, `false` otherwise.
    fileprivate func cleanUpBlockingActivityIndicators() -> Bool {
        let blockingActivityIndicators = blockingActivityIndicators.filter { $0.reference != nil }
        self.blockingActivityIndicators = blockingActivityIndicators
        return blockingActivityIndicators.isEmpty
    }
}

private var associatedObjectKey = 0

// MARK: - WeakReference

// TODO: [WPB-8907] use the type `WeakReference` from WireSystem once WireSystem has become a Swift package.
private struct WeakReference<T: AnyObject> {

    weak var reference: T?

    init(reference: T) {
        self.reference = reference
    }
}
