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

/// Describes the urgency of a piece of work.
///
/// Use this type to communicate how quickly a task should be addressed relative
/// to others. Higher priorities indicate greater urgency or impact, and should
/// generally be reserved for exceptional situations. When in doubt, prefer a
/// lower priority to avoid overload and allow important issues to be peformed
/// quickly.

enum WorkItemPriority: Sendable {

    /// Low priority.
    ///
    /// Use for **non-essential or deferrable background work**.
    ///
    /// Examples include cache cleanup, telemetry uploads, or periodic
    /// maintenance. These tasks can be delayed or suspended without
    /// noticeable impact on the user experience.

    case low

    /// Medium priority.
    ///
    /// The **default priority** for most background work.
    ///
    /// Suitable for tasks that should run reliably but not urgently,
    /// such as data synchronization, scheduled refreshes, or prefetching.
    /// The scheduler may delay these tasks when the app is inactive or
    /// system resources are constrained.

    case medium

    /// High priority.
    ///
    /// For **user-visible or time-sensitive work** that should complete
    /// promptly, but does not require immediate execution.
    ///
    /// Use this for operations that support active user actions, like
    /// uploading a photo or sending a message.

    case high

    /// Blocker priority.
    ///
    /// Indicates a task that **must complete before other dependent work
    /// can proceed**.
    ///
    /// Typically used for setup or critical dependency tasks—such as
    /// refreshing authentication tokens, migrating local storage. The
    /// scheduler should prioritize these before normal background jobs.

    case blocker

}
