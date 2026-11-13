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

#if DEBUG

import Foundation

/// Tracks whether the user session is still in memory, so UI tests can detect leaks after logout.
/// Only active with the `-EnableMemoryTracking` launch argument. Status is shown in Developer Tools.
final class DebugMemoryStatus {

    static let shared = DebugMemoryStatus()

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-EnableMemoryTracking")
    }

    private weak var trackedUserSession: AnyObject?

    func trackUserSession(_ session: AnyObject) {
        guard Self.isEnabled else { return }
        trackedUserSession = session
    }

    var userSessionStatus: String {
        trackedUserSession == nil ? "deallocated" : "retained"
    }

}

#endif
