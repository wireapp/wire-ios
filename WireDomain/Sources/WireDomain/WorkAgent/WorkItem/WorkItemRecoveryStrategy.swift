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

/// Defines the strategy to recover from a failed or unprocessable work item.
///
/// When a `WorkItem` cannot be executed successfully, the worker may throw
/// a `WorkItemRecoveryStrategy` to indicate what should be done with the
/// failed item. This allows the system to decide whether to retry, drop,
/// or escalate the ticket based on the chosen strategy.

enum WorkItemRecoveryStrategy: Error {

    /// The item should be discarded and it will not be retried.
    ///
    /// Use this for tasks that are no longer relevant, redundant, or
    /// when retrying would not be meaningful or safe.

    case drop
}
