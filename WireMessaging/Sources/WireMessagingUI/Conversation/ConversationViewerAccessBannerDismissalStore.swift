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

import Foundation

/// Tracks, per conversation, whether the user has closed the `ConversationViewerAccessBanner`.
///
/// This state is kept in memory only, for the lifetime of the app process, and is intentionally
/// never persisted (no `UserDefaults`, disk, or keychain), so the banner reappears again on next launch.
@MainActor
public final class ConversationViewerAccessBannerDismissalStore {
    public static let shared = ConversationViewerAccessBannerDismissalStore()
    typealias CellName = String

    private var dismissedCellNames: Set<String> = []

    private init() {}

    public func isDismissed(forCellName cellName: String) -> Bool {
        dismissedCellNames.contains(cellName)
    }

    public func markDismissed(forCellName cellName: String) {
        dismissedCellNames.insert(cellName)
    }
}
