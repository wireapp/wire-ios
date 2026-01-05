//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// Generates and submits a work item to repair faulty MLS removal keys if needed.
///
/// This generator checks the journal flag and submits the repair work item
/// to the work agent if repair is required. This pattern keeps the work item internal
/// while allowing it to be triggered from the session initialization or after migrations.

public final class RepairFaultyMLSRemovalKeysGenerator {

    private let journal: any JournalProtocol
    private let repairUseCase: any RepairRemovalKeysUseCaseProtocol
    private let workAgent: WorkAgent

    public init(
        journal: any JournalProtocol,
        repairUseCase: any RepairRemovalKeysUseCaseProtocol,
        workAgent: WorkAgent
    ) {
        self.journal = journal
        self.repairUseCase = repairUseCase
        self.workAgent = workAgent
    }

    /// Checks if repair is needed and submits the work item if so.
    ///
    /// This method can be called multiple times safely - it only submits
    /// the work item if the journal flag is set.

    public func submitWorkItemIfNeeded() {
        guard journal[.isRepairFaultyMLSRemovalKeysRequired] else {
            return
        }

        let workItem = RepairFaultyMLSRemovalKeysWorkItem(
            journal: journal,
            repairUseCase: repairUseCase
        )

        Task { [workAgent] in
            await workAgent.submitItem(workItem)
        }
    }

}
