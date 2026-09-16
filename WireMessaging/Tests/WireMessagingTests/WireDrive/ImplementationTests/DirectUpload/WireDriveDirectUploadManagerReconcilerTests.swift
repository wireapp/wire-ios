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
import Testing

@testable import WireMessagingData
@testable import WireMessagingDomain

/// Covers the launch-time matrix of (persisted state) x (what the session reports) x (staged file
/// present). This is the part of the mechanism that decides whether a user's upload is adopted as
/// still running or surfaced as retryable — it never silently re-sends on the user's behalf — so
/// every row is exercised explicitly.
struct WireDriveDirectUploadManagerReconcilerTests {

    private let sut = WireDriveDirectUploadManager.Reconciler()

    // MARK: - No task yet

    /// A relaunch never resumes a transfer on the user's behalf: with no task and nothing to adopt,
    /// the upload surfaces as failed and retryable instead.
    @Test(arguments: [
        WireDriveDirectUploadRecord.State.staged,
        .preChecked,
        .awaitingStart
    ])
    func failsWhenNoTaskExistsYetAfterARelaunch(_ state: WireDriveDirectUploadRecord.State) {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: state)

        // When
        let actions = plan(records: [record], snapshots: [], isStagedFileAvailable: true)

        // Then
        #expect(actions == [.fail(uploadID: record.uploadID, error: .cancelledBySystem)])
    }

    @Test(arguments: [
        WireDriveDirectUploadRecord.State.staged,
        .preChecked,
        .awaitingStart,
        .uploading
    ])
    func failsWhenTheStagedFileIsGone(_ state: WireDriveDirectUploadRecord.State) {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: state)

        // When
        let actions = plan(records: [record], snapshots: [], isStagedFileAvailable: false)

        // Then
        #expect(actions == [.fail(uploadID: record.uploadID, error: .fileNotFound)])
    }

    /// The write that follows task creation can be lost. Starting a second transfer would upload the
    /// same file twice, so the existing task is adopted instead.
    @Test
    func adoptsALiveTaskThatTheRecordDoesNotKnowAbout() {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .awaitingStart)
        let snapshot = WireDriveDirectUploadTaskSnapshot.fixture(
            uploadID: record.uploadID,
            taskIdentifier: 42,
            state: .running,
            bytesSent: 512,
            totalBytes: 2048
        )

        // When
        let actions = plan(records: [record], snapshots: [snapshot], isStagedFileAvailable: true)

        // Then
        #expect(
            actions == [
                .adoptTask(uploadID: record.uploadID, taskIdentifier: 42, bytesSent: 512, totalBytes: 2048)
            ]
        )
    }

    // MARK: - Uploading

    /// The ordinary suspend-and-resume case: the transfer survived and must not be restarted.
    @Test(arguments: [WireDriveDirectUploadTaskSnapshot.State.running, .suspended])
    func adoptsASurvivingTransfer(_ state: WireDriveDirectUploadTaskSnapshot.State) {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .uploading)
        let snapshot = WireDriveDirectUploadTaskSnapshot.fixture(
            uploadID: record.uploadID,
            taskIdentifier: 7,
            state: state,
            bytesSent: 1024,
            totalBytes: 2048
        )

        // When
        let actions = plan(records: [record], snapshots: [snapshot], isStagedFileAvailable: true)

        // Then
        #expect(
            actions == [
                .adoptTask(uploadID: record.uploadID, taskIdentifier: 7, bytesSent: 1024, totalBytes: 2048)
            ]
        )
    }

    @Test(arguments: [WireDriveDirectUploadTaskSnapshot.State.completed, .canceling])
    func waitsForACompletionThatHasNotBeenAppliedYet(_ state: WireDriveDirectUploadTaskSnapshot.State) {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .uploading)
        let snapshot = WireDriveDirectUploadTaskSnapshot.fixture(
            uploadID: record.uploadID,
            taskIdentifier: 9,
            state: state
        )

        // When
        let actions = plan(records: [record], snapshots: [snapshot], isStagedFileAvailable: true)

        // Then
        #expect(actions == [.awaitCompletion(uploadID: record.uploadID, taskIdentifier: 9)])
    }

    /// The force-quit case. iOS cancels every task in the session and delivers no callback, so the
    /// same local state also results from a transfer that finished while the process was dead.
    /// Restarting blindly would re-send a file that already arrived, so the backend is asked first.
    @Test
    func verifiesRemoteStateWhenAnUploadingTaskHasVanished() {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .uploading)

        // When
        let actions = plan(records: [record], snapshots: [], isStagedFileAvailable: true)

        // Then
        #expect(actions == [.verifyRemoteState(uploadID: record.uploadID)])
    }

    // MARK: - Terminal states

    @Test(arguments: [WireDriveDirectUploadRecord.State.uploaded, .cancelled])
    func cleansUpStagedFilesLeftByTerminalUploads(_ state: WireDriveDirectUploadRecord.State) {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: state)

        // When
        let actions = plan(records: [record], snapshots: [], isStagedFileAvailable: true)

        // Then
        #expect(actions == [.deleteStagedFile(uploadID: record.uploadID)])
    }

    @Test(arguments: [WireDriveDirectUploadRecord.State.uploaded, .cancelled])
    func doesNothingForTerminalUploadsWithNoStagedFile(_ state: WireDriveDirectUploadRecord.State) {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: state)

        // When
        let actions = plan(records: [record], snapshots: [], isStagedFileAvailable: false)

        // Then
        #expect(actions.isEmpty)
    }

    /// A failed upload is left alone: retrying is the user's call, not reconciliation's.
    @Test(arguments: [true, false])
    func leavesFailedUploadsAlone(_ isStagedFileAvailable: Bool) {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .failed, failure: .urlError(error: URLError(.timedOut)))

        // When
        let actions = plan(
            records: [record],
            snapshots: [],
            isStagedFileAvailable: isStagedFileAvailable
        )

        // Then
        #expect(actions.isEmpty)
    }

    // MARK: - Orphans

    @Test
    func cancelsATaskThatNoRecordClaims() {
        // Given — the database was reset, or the account changed.
        let snapshot = WireDriveDirectUploadTaskSnapshot.fixture(uploadID: UUID(), taskIdentifier: 3)

        // When
        let actions = plan(records: [], snapshots: [snapshot], isStagedFileAvailable: true)

        // Then
        #expect(actions == [.cancelOrphanTask(taskIdentifier: 3)])
    }

    @Test
    func cancelsAnUntaggedTask() {
        // Given — a task with no upload identifier can never be accounted for.
        let snapshot = WireDriveDirectUploadTaskSnapshot.fixture(uploadID: nil, taskIdentifier: 4)

        // When
        let actions = plan(records: [], snapshots: [snapshot], isStagedFileAvailable: true)

        // Then
        #expect(actions == [.cancelOrphanTask(taskIdentifier: 4)])
    }

    @Test
    func ignoresFinishedTasksThatNoRecordClaims() {
        // Given — cancelling an already finished task would be pointless.
        let snapshot = WireDriveDirectUploadTaskSnapshot.fixture(
            uploadID: UUID(),
            taskIdentifier: 5,
            state: .completed
        )

        // When
        let actions = plan(records: [], snapshots: [snapshot], isStagedFileAvailable: true)

        // Then
        #expect(actions.isEmpty)
    }

    // MARK: - Multiple uploads

    @Test
    func plansEveryUploadIndependently() {
        // Given
        let notStarted = WireDriveDirectUploadRecord.fixture(state: .staged)
        let finished = WireDriveDirectUploadRecord.fixture(state: .uploaded)
        let vanished = WireDriveDirectUploadRecord.fixture(state: .uploading)

        // When
        let actions = plan(
            records: [notStarted, finished, vanished],
            snapshots: [],
            isStagedFileAvailable: true
        )

        // Then
        #expect(actions.count == 3)
        #expect(actions.contains(.fail(uploadID: notStarted.uploadID, error: .cancelledBySystem)))
        #expect(actions.contains(.deleteStagedFile(uploadID: finished.uploadID)))
        #expect(actions.contains(.verifyRemoteState(uploadID: vanished.uploadID)))
    }

    // MARK: - Helpers

    private func plan(
        records: [WireDriveDirectUploadRecord],
        snapshots: [WireDriveDirectUploadTaskSnapshot],
        isStagedFileAvailable: Bool
    ) -> [WireDriveDirectUploadManager.Reconciler.Action] {
        sut.plan(
            records: records,
            snapshots: snapshots,
            isStagedFileAvailable: { _ in isStagedFileAvailable }
        )
    }
}
