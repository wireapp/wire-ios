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

package import Foundation
import WireLogging
package import WireMessagingDomain

package extension WireDriveDirectUploadManager {

    /// Decides what to do with each persisted upload after a relaunch
    struct Reconciler: Sendable {

        package enum Action: Sendable, Equatable {

            /// A live task was found for a record that claims to be uploading. Rebind to it.
            case adoptTask(uploadID: UUID, taskIdentifier: Int, bytesSent: Int64, totalBytes: Int64)

            /// The completion callback appears to be in flight. Wait briefly before deciding.
            case awaitCompletion(uploadID: UUID, taskIdentifier: Int)

            /// The record claims to be uploading but no task exists. Ask the backend what happened
            /// before failing, so a completed-but-unreported upload is marked uploaded instead of
            /// needlessly surfaced as failed.
            case verifyRemoteState(uploadID: UUID)

            case fail(uploadID: UUID, error: WireDriveUploadError)

            /// A task exists that no record claims.
            case cancelOrphanTask(taskIdentifier: Int)

            /// A terminal record still has a staged file to clean up.
            case deleteStagedFile(uploadID: UUID)
        }

        package init() {}

        package func plan(
            records: [WireDriveDirectUploadRecord],
            snapshots: [WireDriveDirectUploadTaskSnapshot],
            isStagedFileAvailable: (WireDriveDirectUploadRecord) -> Bool
        ) -> [Action] {
            var actions: [Action] = []

            let snapshotsByUploadID = Dictionary(
                snapshots.compactMap { snapshot in snapshot.uploadID.map { ($0, snapshot) } },
                uniquingKeysWith: { first, second in
                    first.isActive ? first : second
                }
            )

            for record in records {
                actions.append(
                    contentsOf: plan(
                        record: record,
                        snapshot: snapshotsByUploadID[record.uploadID],
                        isStagedFileAvailable: isStagedFileAvailable(record)
                    )
                )
            }

            let knownUploadIDs = Set(records.map(\.uploadID))

            for snapshot in snapshots where snapshot.isActive {
                guard let uploadID = snapshot.uploadID else {
                    actions.append(.cancelOrphanTask(taskIdentifier: snapshot.taskIdentifier))
                    continue
                }

                if !knownUploadIDs.contains(uploadID) {
                    // No record for this task: database reset, account switch, or a lost write
                    // after task creation.
                    actions.append(.cancelOrphanTask(taskIdentifier: snapshot.taskIdentifier))
                }
            }

            return actions
        }

        private func plan(
            record: WireDriveDirectUploadRecord,
            snapshot: WireDriveDirectUploadTaskSnapshot?,
            isStagedFileAvailable: Bool
        ) -> [Action] {
            switch record.state {
            case .staged, .preChecked, .awaitingStart:
                // A live task means the write after task creation was lost, adopt it instead of
                // starting a second transfer.
                if let snapshot, snapshot.isActive {
                    return [adopting(snapshot, uploadID: record.uploadID)]
                }

                guard isStagedFileAvailable else {
                    return [.fail(uploadID: record.uploadID, error: .fileNotFound)]
                }

                // No task was ever created, or the process died before it could be. Surface it as
                // failed rather than silently resuming, the user decides whether to retry.
                return [.fail(uploadID: record.uploadID, error: .cancelledBySystem)]

            case .uploading:
                guard isStagedFileAvailable else {
                    return [.fail(uploadID: record.uploadID, error: .fileNotFound)]
                }

                guard let snapshot else {
                    return [.verifyRemoteState(uploadID: record.uploadID)]
                }

                if snapshot.isActive {
                    return [adopting(snapshot, uploadID: record.uploadID)]
                }

                return [
                    .awaitCompletion(uploadID: record.uploadID, taskIdentifier: snapshot.taskIdentifier)
                ]

            case .uploaded, .cancelled:
                return isStagedFileAvailable ? [.deleteStagedFile(uploadID: record.uploadID)] : []

            case .failed:
                return []
            }
        }

        private func adopting(_ snapshot: WireDriveDirectUploadTaskSnapshot, uploadID: UUID) -> Action {
            .adoptTask(
                uploadID: uploadID,
                taskIdentifier: snapshot.taskIdentifier,
                bytesSent: snapshot.bytesSent,
                totalBytes: snapshot.totalBytes
            )
        }
    }
}

// MARK: - Relaunch reconciliation

extension WireDriveDirectUploadManager {

    func reconcile() async {
        let snapshots = await session.currentTasks()
        let plan = reconciler.plan(
            records: Array(records.values),
            snapshots: snapshots,
            isStagedFileAvailable: { [fileCache] record in
                fileCache.exists(stagedFileName: record.stagedFileName)
            }
        )

        for action in plan {
            await execute(action)
        }

        publishToTracker(replacingAll: true)
    }

    func execute(_ action: Reconciler.Action) async {
        switch action {
        case let .adoptTask(uploadID, taskIdentifier, bytesSent, totalBytes):
            // The transfer survived: rebind to it rather than starting a second one.
            await transition(uploadID: uploadID) {
                $0.state = .uploading
                $0.taskIdentifier = taskIdentifier
            }

            if totalBytes > 0 {
                let fraction = clampedFraction(bytesSent, of: totalBytes)
                progress[uploadID] = fraction
                tracker.updateProgress(uploadID: uploadID, progress: fraction)
            }

        case let .awaitCompletion(uploadID, _):
            // Finished but no callback yet; give it a moment before falling through to the
            // ambiguous path.
            scheduleDeferred(uploadID) { [weak self] in
                try? await Task.sleep(for: .seconds(Constants.completionWatchdog))
                await self?.resolveIfStillUploading(uploadID: uploadID)
            }

        case let .verifyRemoteState(uploadID):
            await verifyRemoteState(uploadID: uploadID)

        case let .fail(uploadID, error):
            await handleFailure(uploadID: uploadID, error: error)

        case let .cancelOrphanTask(taskIdentifier):
            WireLogger.wireDrive.warn("cancelling orphaned drive upload task \(taskIdentifier)")
            await session.cancelTask(taskIdentifier: taskIdentifier)

        case let .deleteStagedFile(uploadID):
            guard let record = records[uploadID] else { return }
            try? fileCache.delete(stagedFileName: record.stagedFileName)
        }
    }

    func resolveIfStillUploading(uploadID: UUID) async {
        guard let record = records[uploadID], record.state == .uploading else { return }
        await verifyRemoteState(uploadID: uploadID)
    }

    func verifyRemoteState(uploadID: UUID) async {
        guard let record = records[uploadID] else { return }

        do {
            _ = try await nodesAPI.getNode(nodeID: record.nodeID)
            let versions = try await nodesAPI.getVersions(nodeID: record.nodeID)

            if versions.contains(where: { $0.id == record.versionID }) {
                // The bytes already landed; nothing left to do but mark it done.
                try? fileCache.delete(stagedFileName: record.stagedFileName)
                await transition(uploadID: uploadID) {
                    $0.state = .uploaded
                    $0.taskIdentifier = nil
                }
                progress[uploadID] = 1
                publishToTracker()
                return
            }
        } catch {
            WireLogger.wireDrive.info("could not verify drive upload remote state: \(error)")
        }

        guard fileCache.exists(stagedFileName: record.stagedFileName) else {
            await handleFailure(uploadID: uploadID, error: .fileNotFound)
            return
        }

        await handleFailure(uploadID: uploadID, error: .cancelledBySystem)
    }
}
