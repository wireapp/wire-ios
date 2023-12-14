//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

enum ExternalCommitError: Error, Equatable {

    case failedToSendCommit(recovery: Recovery)
    case failedToMergePendingGroup
    case failedToClearPendingGroup

    enum Recovery {

        /// Retry the action from the beginning
        case retry

        /// Abort the action and log the error
        case giveUp

    }
}

extension ExternalCommitError.Recovery {

    /// Whether the pending group should be cleared

    var shouldClearPendingGroup: Bool {
        switch self {
        case .retry:
            return false

        case .giveUp:
            return true
        }
    }

}
