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

// MARK: - CommitError

enum CommitError: Error, Equatable {
    case failedToGenerateCommit
    case failedToSendCommit(recovery: RecoveryStrategy, cause: SendCommitBundleAction.Failure)
    case failedToMergeCommit
    case failedToClearCommit
    case noPendingProposals

    // MARK: Internal

    enum RecoveryStrategy: Equatable {
        /// Perform a quick sync, then commit pending proposals.
        ///
        /// Core Crypto can automatically recover if it processes all
        /// incoming handshake messages. It will migrate any pending
        /// commits/proposals, which can then be committed as pending
        /// proposals.

        case commitPendingProposalsAfterQuickSync

        /// Perform a quick sync, then retry the action in its entirety.
        ///
        /// Core Crypto can not automatically recover by itself. It needs
        /// to process incoming handshake messages then generate a new commit.

        case retryAfterQuickSync

        /// Repair (re-join) the group and retry the action
        ///
        /// We may have missed a few commits so we will rejoin the group
        /// and try again.

        case retryAfterRepairingGroup

        /// Abort the action and inform the user.
        ///
        /// There is no way to automatically recover from the error.

        case giveUp
    }
}

extension CommitError.RecoveryStrategy {
    /// Whether the pending commit should be discarded.

    var shouldDiscardCommit: Bool {
        switch self {
        case .commitPendingProposalsAfterQuickSync:
            false

        case .retryAfterQuickSync, .giveUp, .retryAfterRepairingGroup:
            true
        }
    }
}
