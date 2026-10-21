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

    /// The share extension leaves main-app outbox ownership with the main app.
    public var canProcessOfflinePendingMessages: Bool {
        userInfo["canProcessOfflinePendingMessages"] as? Bool ?? true
    }

    public func disableOfflinePendingMessageProcessing() {
        offlinePendingMessagesEnabled = false
        userInfo["canProcessOfflinePendingMessages"] = false
    }
}
