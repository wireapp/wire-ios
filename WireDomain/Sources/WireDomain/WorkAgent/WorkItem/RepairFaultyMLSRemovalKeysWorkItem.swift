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
import WireLogging

/// Repairs conversations with faulty MLS removal keys.
///
/// This work item checks if the journal flag `isRepairFaultyMLSRemovalKeysRequired`
/// is set, and if so, invokes the repair use case. On successful completion,
/// the flag is cleared so the repair only runs once per migration.

struct RepairFaultyMLSRemovalKeysWorkItem: WorkItem {

    let id = UUID()
    var priority: WorkItemPriority {
        .low
    }

    private let journal: any JournalProtocol
    private let repairUseCase: any RepairRemovalKeysUseCaseProtocol

    init(
        journal: any JournalProtocol,
        repairUseCase: any RepairRemovalKeysUseCaseProtocol
    ) {
        self.journal = journal
        self.repairUseCase = repairUseCase
    }

    func start() async throws {
        // Check if repair is needed
        guard journal[.isRepairFaultyMLSRemovalKeysRequired] else {
            WireLogger.mls.debug(
                "faulty MLS removal keys repair not needed, skipping",
                attributes: .safePublic
            )
            return
        }

        WireLogger.mls.info(
            "starting faulty MLS removal keys repair",
            attributes: .safePublic
        )

        do {
            let result = try await repairUseCase.invoke()

            WireLogger.mls.info(
                "faulty MLS removal keys repair completed: found \(result.faultyConversationsFound), repaired \(result.conversationsRepaired)",
                attributes: .safePublic
            )

            // Clear the flag on success
            journal[.isRepairFaultyMLSRemovalKeysRequired] = false

        } catch {
            WireLogger.mls.error(
                "faulty MLS removal keys repair failed: \(String(describing: error))",
                attributes: .safePublic
            )
            // Don't clear the flag so it will be retried
            throw error
        }
    }

}
