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

import WireDataModel
import WireLogging

// sourcery: AutoMockable
public protocol MLSGroupRepairAgentProtocol {

    func repairConversations() async

}

final class MLSGroupRepairAgent: MLSGroupRepairAgentProtocol {

    private let journal: Journal
    private let mlsService: MLSServiceInterface

    // MARK: - Life cycle

    public init(
        journal: Journal,
        mlsService: MLSServiceInterface
    ) {
        self.journal = journal
        self.mlsService = mlsService
    }

    public func repairConversations() async {
        let brokenGroupIDs = journal[.brokenMLSGroupIDs]
        guard !brokenGroupIDs.isEmpty else {
            WireLogger.sync.debug("No broken MLS groups to repair")
            return
        }

        WireLogger.sync.debug("Repairing \(brokenGroupIDs.count) MLS groups")

        let mlsGroups: [(String, MLSGroupID)] = brokenGroupIDs.compactMap { groupIDString in
            guard let mlsGroupID = MLSGroupID(base64Encoded: groupIDString) else {
                WireLogger.sync.warn("Invalid MLS group ID: \(groupIDString)")
                return nil
            }
            return (groupIDString, mlsGroupID)
        }

        for (groupID, mlsGroupID) in mlsGroups {
            await mlsService.fetchAndRepairGroup(
                with: mlsGroupID,
                shouldPerformIncrementalSync: false
            )
            journal.removeValue(groupID, for: .brokenMLSGroupIDs)
            WireLogger.sync.debug("Successfully repaired group: \(groupID)")
        }
    }

}
