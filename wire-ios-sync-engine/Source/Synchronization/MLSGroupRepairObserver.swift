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

import Combine
import Foundation
import WireDomain
import WireLogging

final class MLSGroupRepairObserver {

    private let repairAgent: any RepairAgentProtocol
    private let journal: Journal
    private let mlsService: MLSServiceInterface
    private let decryptionQueue = DispatchQueue(label: "decryptionQueue")
    private var cancellables = Set<AnyCancellable>()

    init(
        repairAgent: any RepairAgentProtocol,
        journal: Journal,
        mlsService: MLSServiceInterface
    ) {
        self.repairAgent = repairAgent
        self.journal = journal
        self.mlsService = mlsService
        setupObservation()
    }

    private func setupObservation() {
        if repairAgent.isSyncV2Enabled {
            repairAgent
                .syncStatePublisher
                .receive(on: decryptionQueue)
                .sink { [weak self] state in
                    guard case .liveSyncing = state else { return }
                    self?.handleLiveSyncing()
                }
                .store(in: &cancellables)
        } else {
            // TODO: for legacy sync
        }
    }

    private func handleLiveSyncing() {
        let brokenGroupIDs = journal[.brokenMLSGroupIDs]
        guard !brokenGroupIDs.isEmpty else {
            WireLogger.sync.debug("No broken MLS groups to repair")
            return
        }

        WireLogger.sync.debug("Repairing \(brokenGroupIDs.count) MLS groups")

        brokenGroupIDs
            .compactMap { groupID -> (String, MLSGroupID)? in
                guard let mlsGroupID = MLSGroupID(base64Encoded: groupID) else {
                    WireLogger.sync.warn("Invalid convert string to MLS group ID: \(groupID)")
                    return nil
                }
                return (groupID, mlsGroupID)
            }
            .forEach { groupID, mlsGroupID in
                Task {
                    await mlsService.fetchAndRepairGroup(with: mlsGroupID)
                    journal.removeValue(groupID, for: .brokenMLSGroupIDs)
                    WireLogger.sync.debug("Successfully repaired group: \(groupID)")
                }
            }
    }
}
