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

/// Repairs MLS conversations which are out of sync (broken).
///
/// This work item triggers repairing conversations which are within the journal values `brokenMLSGroupIDs`
/// Note: this item is cleared when sync is suspended
struct RepairBrokenMLSGroupsItem: WorkItem {
    var id: String {
        "RepairBrokenMLSGroupsItem_\(_internalID.uuidString)"
    }
    
    let _internalID = UUID()
    
    var priority: WorkItemPriority {
        .medium
    }

    private let repairAgent: any MLSGroupRepairAgentProtocol

    init(
        repairAgent: any MLSGroupRepairAgentProtocol
    ) {
        self.repairAgent = repairAgent
    }

    func start() async throws {
        WireLogger.mls.info("starting repairing broken MLS groups", attributes: .safePublic)
        await repairAgent.repairConversations()
    }

}
