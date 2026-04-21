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

protocol ExpiringActivityManagerProtocol: Sendable {

    /// Track a task under the shared expiring activity. If this is the first
    /// active task, an expiring activity is registered with the system.
    ///
    /// - Parameters:
    ///   - reason: A human-readable reason used for logging.
    ///   - task: The task to protect. It will be cancelled if the system reclaims background time.
    func track(reason: String, task: Task<some Sendable, some Error>) async

}
