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
import WireDataModel
import WireDomain
import WireFoundation
import WireLogging
import WireUtilities

// sourcery: AutoMockable
protocol MLSGroupRepairAgentProtocol {

    var isSyncV2Enabled: Bool { get }

}

final class MLSGroupRepairAgent: MLSGroupRepairAgentProtocol {

    var isSyncV2Enabled: Bool {
        journal[.isSyncV2Enabled]
    }

    typealias AttemptCount = Int

    private let syncStatePublisher: AnyPublisher<SyncState, Never>
    private let maxAttemptCount = 4
    private var attemptsToRepair: [String: AttemptCount] = [:]
    private let journal: Journal
    private let mlsService: MLSServiceInterface
    private let decryptionQueue = DispatchQueue(label: "decryptionQueue")
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Life cycle

    init(
        journal: Journal,
        mlsService: MLSServiceInterface,
        syncStatePublisher: AnyPublisher<SyncState, Never>
    ) {
        self.journal = journal
        self.mlsService = mlsService
        self.syncStatePublisher = syncStatePublisher
        setupObservation()
    }

    private func setupObservation() {
        if isSyncV2Enabled {
            syncStatePublisher
                .receive(on: decryptionQueue)
                .sink { [weak self] state in
                    guard case .liveSyncing(.ongoing) = state else { return }
                    self?.repairConversations()
                }
                .store(in: &cancellables)
        }
    }

    private func repairConversations() {
        clearBrokenMLSGroups()

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

        mlsGroups.forEach {
            let attemptsToRepairCount = attemptsToRepair[$0.0, default: 0]
            attemptsToRepair[$0.0] = attemptsToRepairCount + 1
        }

        Task {
            for (groupID, mlsGroupID) in mlsGroups {
                await mlsService.fetchAndRepairGroup(with: mlsGroupID)
                journal.removeValue(groupID, for: .brokenMLSGroupIDs)
                WireLogger.sync.debug("Successfully repaired group: \(groupID)")
            }
        }
    }

    private func clearBrokenMLSGroups() {
        let brokenGroupIDs = journal[.brokenMLSGroupIDs]

        // Attempted to repair these MLS groups multiple times to no avail, clean them up to avoid an infinite loop
        let unrecoverableMLSGroups = attemptsToRepair.filter {
            $0.value == maxAttemptCount
        }.map(\.key)

        // These MLS groups were recovered
        let recoveredMLSGroups = attemptsToRepair.filter {
            !brokenGroupIDs.contains($0.key)
        }.map(\.key)

        let mlsGroupsToRemove = unrecoverableMLSGroups + recoveredMLSGroups

        mlsGroupsToRemove.forEach {
            attemptsToRepair[$0] = nil
            journal.removeValue($0, for: .brokenMLSGroupIDs)
        }
    }

}
