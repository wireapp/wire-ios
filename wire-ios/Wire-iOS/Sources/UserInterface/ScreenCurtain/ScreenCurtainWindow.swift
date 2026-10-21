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
import WireSyncEngine

/// A window used to obfuscate the main content window when the app is inactive.
final class ScreenCurtainWindow: UIWindow {

    // MARK: - Properties

    weak var userSession: UserSession?

    // MARK: - Life cycle

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)

        rootViewController = UIHostingController(rootView: ScreenCurtainView())
        backgroundColor = .clear
        isOpaque = false
        windowLevel = .statusBar - 1
        accessibilityIdentifier = "screen_curtain_window"
        accessibilityViewIsModal = true
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Visibility

    /// Show the curtain if the current user session requires it.
    func showIfNeeded() {
        isHidden = !(userSession?.requiresScreenCurtain ?? false)
    }

    /// Hide the curtain. Called when the owning scene becomes active.
    func hide() {
        isHidden = true
    }
}
