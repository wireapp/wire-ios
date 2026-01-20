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

protocol ZMSyncStateDelegate: AnyObject {

    /// The session did start the slow sync (fetching of users, conversations, ...)
    func didStartSlowSync()

    /// The session did finish the slow sync
    func didFinishSlowSync()

    /// The session did start the quick sync (fetching of the notification stream)
    func didStartQuickSync()

    /// The session did finish the quick sync
    /// - Parameter isRecovering: Set to true when trying to recover after failing some MLS operations (see
    /// `MLSService`)
    func didFinishQuickSync(isRecovering: Bool)

}
