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

import CoreData

extension NSManagedObjectContext {
    /// Sampled when the stack starts. Recovery of enrolled messages does not consult this flag.
    public internal(set) var offlinePendingMessagesEnabled: Bool {
        get { userInfo["offlinePendingMessagesEnabled"] as? Bool ?? false }
        set { userInfo["offlinePendingMessagesEnabled"] = newValue }
    }

    /// Processing is independent of enrollment so existing work survives disabling the feature flag.
    /// The share extension opts out because it has no cross-process claim on main-app outbox work.
    public var canProcessOfflinePendingMessages: Bool {
        userInfo["canProcessOfflinePendingMessages"] as? Bool ?? true
    }

    /// Disables both creation and recovery for contexts that must not own the main app's queue.
    public func disableOfflinePendingMessageProcessing() {
        offlinePendingMessagesEnabled = false
        userInfo["canProcessOfflinePendingMessages"] = false
    }
}
