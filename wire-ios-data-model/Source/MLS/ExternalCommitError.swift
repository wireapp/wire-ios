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

import Foundation

// MARK: - ExternalCommitError

enum ExternalCommitError: Error, Equatable {
    case failedToSendCommit(recovery: RecoveryStrategy, cause: SendCommitBundleAction.Failure)
    case failedToMergePendingGroup
    case failedToClearPendingGroup

    // MARK: Internal

    enum RecoveryStrategy {
        /// Retry the action from the beginning
        case retry

        /// Abort the action and log the error
        case giveUp
    }
}

extension ExternalCommitError.RecoveryStrategy {
    /// Whether the pending group should be cleared

    var shouldClearPendingGroup: Bool {
        switch self {
        case .retry:
            false

        case .giveUp:
            true
        }
    }
}
