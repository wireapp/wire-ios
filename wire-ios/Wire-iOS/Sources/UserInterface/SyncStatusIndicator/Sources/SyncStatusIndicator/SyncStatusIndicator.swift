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

/// An indicator for sync activity and connectivy.
/// It presents itself in a separate window, at the top of the screen.
/// It resizes the key window accordingly.
@MainActor
public struct SyncStatusIndicator {

    public var syncStatus: SyncStatus? {
        didSet { applySyncStatus() }
    }

    /// The window where the indicator is presented.
    private let syncStatusWindow: UIWindow
    /// The root view controller of the `syncStatusWindow`.
    private let syncStatusViewController: SyncStatusIndicatorViewController

    private var windowScene: UIWindowScene? { syncStatusWindow.windowScene }
    private var keyWindow: UIWindow? { windowScene?.keyWindow }

    public init(windowScene: UIWindowScene) {
        syncStatusWindow = .init(windowScene: windowScene)
        syncStatusViewController = .init()

        // present above the key window
        let keyWindowLevel = keyWindow?.windowLevel ?? .normal
        syncStatusWindow.windowLevel = .init(keyWindowLevel.rawValue + 1)
        syncStatusWindow.isUserInteractionEnabled = false
        syncStatusWindow.rootViewController = syncStatusViewController
    }

    private func applySyncStatus() {
        syncStatusViewController.syncStatusIndicatorView.syncStatus = syncStatus
    }
}
