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

import Combine
import Foundation
import Testing
import UniformTypeIdentifiers

@testable import WireMessagingData
@testable import WireMessagingDomain
@testable import WireMessagingDomainSupport

@MainActor
final class WireDriveDirectUploadManagerTests {

    private let nodesAPI = MockNodesAPIProtocol()
    private let store = MockWireDriveDirectUploadStoreProtocol()
    private let fileCache = MockWireDriveDirectUploadFileCacheProtocol()
    private let session = MockWireDriveDirectUploadSessionProtocol()
    private let accessToken = MockAccessTokenProvider()
    private let tracker = WireDriveObserveDirectUploadsUseCase()

    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let stagedURL = URL(fileURLWithPath: "/tmp/staged/report.pdf")

    private lazy var sut = WireDriveDirectUploadManager(
        nodesAPI: nodesAPI,
        store: store,
        fileCache: fileCache,
        session: session,
        accessTokenProvider: accessToken,
        tracker: tracker,
        retryBackoff: [0, 0],
        now: { [now] in now }
    )

    init() {
        session.identifier = "com.wire.drive.upload-test"
        session.setEventSink_MockMethod = { _ in }
        session.removeEventSink_MockMethod = {}
        session.cancelTaskUploadID_MockMethod = { _ in }
        session.cancelTaskTaskIdentifier_MockMethod = { _ in }
        session.cancelAllTasks_MockMethod = {}
        session.invalidate_MockMethod = {}
        session.currentTasks_MockValue = []
        session.startUploadUploadIDRequestFileURL_MockValue = 1

        store.fetchAll_MockValue = []
        store.fetchUploadID_MockValue = nil
        store.fetchStates_MockValue = []
        store.upsert_MockMethod = { _ in }
        store.upsertRecords_MockMethod = { _ in }
        store.deleteUploadIDs_MockMethod = { _ in }
        store.deleteAll_MockMethod = {}

        fileCache.existsStagedFileName_MockValue = true
        fileCache.urlStagedFileName_MockMethod = { [stagedURL] _ in stagedURL }
        fileCache.deleteStagedFileName_MockMethod = { _ in }
        fileCache.sweepOrphansReferencedFileNamesGracePeriod_MockMethod = { _, _ in }
        fileCache.stageSourceURLUploadIDFileNameIsSecurityScoped_MockMethod = { _, uploadID, fileName, _ in
            WireDriveStagedFile(
                fileName: "\(uploadID.uuidString)_\(fileName)",
                url: URL(fileURLWithPath: "/tmp/s"),
                size: 2048
            )
        }

        accessToken.accessToken_MockValue = WireDriveAccessToken(
            token: "token",
            expirationDate: now.addingTimeInterval(900)
        )

        nodesAPI.preCheckNodePathFindAvailablePath_MockValue = .success
        nodesAPI.presignedUploadURLNodeVersionIDExpiration_MockValue = URL(string: "https://example.com/put")!
        nodesAPI.deleteNodesNodeIDsPermanently_MockValue = true
    }

    // MARK: - Enqueuing

    @Test
    func enqueue_rejectsAnEmptyBatch() async {
        await #expect(throws: WireDriveDirectUploadBatchError.noFiles) {
            try await sut.enqueue(sources: [], destinationFolderPath: "cell-1")
        }
    }

    /// The picker's selection limit is a convenience; this is the guarantee.
    @Test
    func enqueue_rejectsABatchOverTheLimit() async {
        // Given
        let sources = (0 ... WireDriveDirectUploadLimits.maxFilesPerBatch).map { makeSource(named: "f\($0).pdf") }

        // Then
        await #expect(
            throws: WireDriveDirectUploadBatchError.tooManyFiles(limit: WireDriveDirectUploadLimits.maxFilesPerBatch)
        ) {
            try await sut.enqueue(sources: sources, destinationFolderPath: "cell-1")
        }
    }

    @Test
    func enqueue_acceptsExactlyTheLimit() async throws {
        // Given
        let sources = (0 ..< WireDriveDirectUploadLimits.maxFilesPerBatch).map { makeSource(named: "f\($0).pdf") }

        // When
        _ = try await sut.enqueue(sources: sources, destinationFolderPath: "cell-1")

        // Then
        let summary = tracker.summary
        #expect(summary.items.count == WireDriveDirectUploadLimits.maxFilesPerBatch)
    }

    /// A backstop against a retry-all storm, or a user queueing batch after batch.
    @Test
    func enqueue_stopsAdmittingAtTheActiveUploadCeiling() async throws {
        // Given — four full batches is more than the ceiling allows.
        let batchSize = WireDriveDirectUploadLimits.maxFilesPerBatch

        // When
        for batch in 0 ..< 4 {
            _ = try await sut.enqueue(
                sources: (0 ..< batchSize).map { makeSource(named: "b\(batch)-f\($0).pdf") },
                destinationFolderPath: "cell-1"
            )
        }
        await sut.waitForPendingWork()

        // Then
        let summary = tracker.summary
        #expect(summary.items.count == 60)
    }

    @Test
    func enqueue_stagesEveryFileAndTracksThem() async throws {
        // Given
        let sources = [makeSource(named: "a.pdf"), makeSource(named: "b.pdf")]

        // When
        let batchID = try await sut.enqueue(sources: sources, destinationFolderPath: "cell-1/Documents")

        // Then
        #expect(fileCache.stageSourceURLUploadIDFileNameIsSecurityScoped_Invocations.count == 2)

        let summary = tracker.summary
        #expect(summary.items.count == 2)
        #expect(summary.items.allSatisfy { $0.batchID == batchID })
        #expect(summary.items.allSatisfy { $0.destinationFolderPath == "cell-1/Documents" })
    }

    /// One unreadable file must not abort the rest of the batch.
    @Test
    func enqueue_skipsFilesThatCannotBeStaged() async throws {
        // Given
        fileCache.stageSourceURLUploadIDFileNameIsSecurityScoped_MockMethod = { _, uploadID, fileName, _ in
            guard fileName != "bad.pdf" else {
                throw WireDriveDirectUploadStagingError.copyFailed("nope")
            }
            return WireDriveStagedFile(
                fileName: "\(uploadID.uuidString)_\(fileName)",
                url: URL(fileURLWithPath: "/tmp/s"),
                size: 2048
            )
        }

        // When
        _ = try await sut.enqueue(
            sources: [makeSource(named: "good.pdf"), makeSource(named: "bad.pdf")],
            destinationFolderPath: "cell-1"
        )

        // Then
        let summary = tracker.summary
        #expect(summary.items.map(\.fileName) == ["good.pdf"])
    }

    @Test
    func enqueue_throwsWhenNothingCouldBeStaged() async {
        // Given
        fileCache.stageSourceURLUploadIDFileNameIsSecurityScoped_MockMethod = { _, _, _, _ in
            throw WireDriveDirectUploadStagingError.copyFailed("nope")
        }

        // Then
        await #expect(throws: (any Error).self) {
            try await sut.enqueue(sources: [makeSource(named: "a.pdf")], destinationFolderPath: "cell-1")
        }
    }

    @Test
    func enqueue_sanitisesFileNames() async throws {
        // When
        _ = try await sut.enqueue(
            sources: [makeSource(named: "a/b.pdf")],
            destinationFolderPath: "cell-1"
        )

        // Then — a separator would otherwise be read as a path component by the backend.
        let summary = tracker.summary
        #expect(summary.items.first?.fileName == "a_b.pdf")
    }

    // MARK: - Pipeline

    @Test
    func enqueue_preChecksPresignsAndStartsATask() async throws {
        // When
        _ = try await sut.enqueue(sources: [makeSource(named: "a.pdf")], destinationFolderPath: "cell-1")
        await sut.waitForPendingWork()

        // Then
        #expect(nodesAPI.preCheckNodePathFindAvailablePath_Invocations.count == 1)
        let preCheck = try #require(nodesAPI.preCheckNodePathFindAvailablePath_Invocations.first)
        #expect(preCheck.nodePath == "cell-1/a.pdf")
        #expect(preCheck.findAvailablePath == true)

        #expect(nodesAPI.presignedUploadURLNodeVersionIDExpiration_Invocations.count == 1)
        #expect(session.startUploadUploadIDRequestFileURL_Invocations.count == 1)
    }

    @Test
    func enqueue_appliesTheResolvedPathWhenTheNameIsTaken() async throws {
        // Given
        nodesAPI.preCheckNodePathFindAvailablePath_MockValue = .fileExists(nextPath: "cell-1/a (1).pdf")

        // When
        _ = try await sut.enqueue(sources: [makeSource(named: "a.pdf")], destinationFolderPath: "cell-1")
        await sut.waitForPendingWork()

        // Then
        let presign = try #require(nodesAPI.presignedUploadURLNodeVersionIDExpiration_Invocations.first)
        #expect(presign.node.path == "cell-1/a (1).pdf")
    }

    /// A presigned URL cannot outlive the credentials it was signed with, and Wire access tokens are
    /// short lived.
    @Test
    func enqueue_boundsPresignedURLLifetimeByTheAccessToken() async throws {
        // Given
        accessToken.accessToken_MockValue = WireDriveAccessToken(
            token: "token",
            expirationDate: now.addingTimeInterval(300)
        )

        // When
        _ = try await sut.enqueue(sources: [makeSource(named: "a.pdf")], destinationFolderPath: "cell-1")
        await sut.waitForPendingWork()

        // Then
        let presign = try #require(nodesAPI.presignedUploadURLNodeVersionIDExpiration_Invocations.first)
        #expect(presign.expiration == 300)
    }

    @Test
    func enqueue_sendsAPutRequestWithNoApplicationHeaders() async throws {
        // When
        _ = try await sut.enqueue(sources: [makeSource(named: "a.pdf")], destinationFolderPath: "cell-1")
        await sut.waitForPendingWork()

        // Then — a presigned PUT carries its metadata as signed query items; an extra header would
        // invalidate the signature.
        let upload = try #require(session.startUploadUploadIDRequestFileURL_Invocations.first)
        #expect(upload.request.httpMethod == "PUT")
        #expect(upload.request.allHTTPHeaderFields?.isEmpty != false)
        #expect(upload.fileURL == stagedURL)
    }

    @Test
    func enqueue_failsTheUploadWhenPreCheckFails() async throws {
        // Given
        nodesAPI.preCheckNodePathFindAvailablePath_MockError = URLError(.notConnectedToInternet)

        // When
        _ = try await sut.enqueue(sources: [makeSource(named: "a.pdf")], destinationFolderPath: "cell-1")
        await sut.waitForPendingWork()

        // Then
        let summary = tracker.summary
        #expect(summary.failedCount == 1)
        #expect(session.startUploadUploadIDRequestFileURL_Invocations.isEmpty)
    }

    @Test
    func enqueue_failsTheUploadWhenTheStagedFileVanishesBeforeStarting() async throws {
        // Given
        fileCache.existsStagedFileName_MockValue = false

        // When
        _ = try await sut.enqueue(sources: [makeSource(named: "a.pdf")], destinationFolderPath: "cell-1")
        await sut.waitForPendingWork()

        // Then
        let summary = tracker.summary
        #expect(summary.items.first?.status == .failed(error: .fileNotFound))
        #expect(summary.items.first?.isRetryable == false)
    }

    /// Pre-checks stay sequential (see the type doc for why), but that must not force the whole
    /// batch to queue behind the slowest one: an upload starts transferring as soon as its own
    /// pre-check resolves, even while a later file in the same batch is still being pre-checked.
    @Test
    func enqueue_startsAnEarlierUploadWithoutWaitingForALaterOnesPreCheck() async throws {
        // Given
        let bPreCheckGate = AsyncGate()

        nodesAPI.preCheckNodePathFindAvailablePath_MockMethod = { nodePath, _ in
            if nodePath == "cell-1/b.pdf" {
                await bPreCheckGate.wait()
            }
            return .success
        }

        // When
        _ = try await sut.enqueue(
            sources: [makeSource(named: "a.pdf"), makeSource(named: "b.pdf")],
            destinationFolderPath: "cell-1"
        )

        // Advance the deferred pipeline until "a" has reached a running transfer, without ever
        // opening "b"'s gate.
        var attempts = 0
        while session.startUploadUploadIDRequestFileURL_Invocations.isEmpty, attempts < 1000 {
            await Task.yield()
            attempts += 1
        }

        // Then — "a" started transferring while "b" is still stuck pre-checking, proving the
        // former did not wait on the latter.
        #expect(session.startUploadUploadIDRequestFileURL_Invocations.count == 1)
        #expect(nodesAPI.preCheckNodePathFindAvailablePath_Invocations.count == 2)

        // Cleanup
        await bPreCheckGate.open()
        await sut.waitForPendingWork()
        #expect(session.startUploadUploadIDRequestFileURL_Invocations.count == 2)
    }

    // MARK: - Completion

    @Test
    func completion_marksTheUploadUploadedOnSuccess() async throws {
        // Given
        let uploadID = try await enqueueOne()

        // When
        await sut.handle([.completed(uploadID: uploadID, statusCode: 200, responseBody: nil, error: nil)])

        // Then
        let summary = tracker.summary
        #expect(summary.items.first?.status == .uploaded)
    }

    @Test
    func completion_deletesTheStagedFileOnceUploaded() async throws {
        // Given
        let uploadID = try await enqueueOne()

        // When
        await sut.handle([.completed(uploadID: uploadID, statusCode: 200, responseBody: nil, error: nil)])

        // Then
        #expect(!fileCache.deleteStagedFileName_Invocations.isEmpty)
    }

    /// Almost always an expired presigned URL, which the user should never see.
    @Test
    func completion_silentlyRePresignsOnRejectedCredentials() async throws {
        // Given
        let uploadID = try await enqueueOne()
        let presignsBefore = nodesAPI.presignedUploadURLNodeVersionIDExpiration_Invocations.count

        // When
        await sut.handle([.completed(uploadID: uploadID, statusCode: 403, responseBody: nil, error: nil)])
        await sut.waitForPendingWork()

        // Then
        #expect(nodesAPI.presignedUploadURLNodeVersionIDExpiration_Invocations.count > presignsBefore)

        let summary = tracker.summary
        #expect(summary.failedCount == 0)
    }

    @Test
    func completion_surfacesRejectedCredentialsOnceTheRestartBudgetIsSpent() async throws {
        // Given
        let uploadID = try await enqueueOne()

        // When — each restart consumes one attempt.
        for _ in 0 ... WireDriveDirectUploadManager.ErrorClassifier.maximumSilentRestarts {
            await sut.handle([.completed(uploadID: uploadID, statusCode: 403, responseBody: nil, error: nil)])
            await sut.waitForPendingWork()
        }

        // Then
        let summary = tracker.summary
        #expect(summary.items.first?.status == .failed(error: .unauthorized))
    }

    @Test
    func completion_rePreChecksOnPathCollision() async throws {
        // Given
        let uploadID = try await enqueueOne()
        let preChecksBefore = nodesAPI.preCheckNodePathFindAvailablePath_Invocations.count

        // When
        await sut.handle([.completed(uploadID: uploadID, statusCode: 409, responseBody: nil, error: nil)])
        await sut.waitForPendingWork()

        // Then
        #expect(nodesAPI.preCheckNodePathFindAvailablePath_Invocations.count > preChecksBefore)
    }

    @Test
    func completion_failsPermanentlyOnARejectedRequest() async throws {
        // Given
        let uploadID = try await enqueueOne()

        // When
        await sut.handle([.completed(uploadID: uploadID, statusCode: 400, responseBody: nil, error: nil)])

        // Then
        let summary = tracker.summary
        #expect(summary.items.first?.status == .failed(error: .serverError(statusCode: 400)))
    }

    @Test
    func completion_ignoresAnUnknownUpload() async {
        // When
        await sut.handle([.completed(uploadID: UUID(), statusCode: 200, responseBody: nil, error: nil)])

        // Then
        #expect(fileCache.deleteStagedFileName_Invocations.isEmpty)
    }

    // MARK: - Progress

    @Test
    func progress_reachesTheTrackerWithoutTouchingTheStore() async throws {
        // Given
        let uploadID = try await enqueueOne()
        let writesBefore = store.upsert_Invocations.count + store.upsertRecords_Invocations.count

        // When
        await sut.handle([.progress(uploadID: uploadID, bytesSent: 512, totalBytes: 2048)])

        // Then
        let summary = tracker.summary
        #expect(summary.items.first?.status == .uploading(progress: 0.25))

        // Progress must never be persisted: it arrives many times a second per transfer.
        #expect(store.upsert_Invocations.count + store.upsertRecords_Invocations.count == writesBefore)
    }

    @Test
    func progress_isIgnoredForATerminalUpload() async throws {
        // Given
        let uploadID = try await enqueueOne()
        await sut.cancel(uploadID: uploadID)

        // When
        await sut.handle([.progress(uploadID: uploadID, bytesSent: 512, totalBytes: 2048)])

        // Then — a cancelled upload is gone, so a late progress sample must not bring it back.
        #expect(tracker.summary.items.isEmpty)
    }

    /// iOS can silently reconnect a background upload as part of its own resumable-upload retry,
    /// with no error ever reaching `handleCompletion`. The reconnected leg then reports its own,
    /// lower `totalBytesSent` — the displayed progress must not jump backwards because of it.
    @Test
    func progress_neverMovesBackwards() async throws {
        // Given
        let uploadID = try await enqueueOne()
        await sut.handle([.progress(uploadID: uploadID, bytesSent: 1536, totalBytes: 2048)])
        #expect(tracker.summary.items.first?.status == .uploading(progress: 0.75))

        // When — a silent reconnect resumed sending from an earlier point.
        await sut.handle([.progress(uploadID: uploadID, bytesSent: 512, totalBytes: 2048)])

        // Then
        #expect(tracker.summary.items.first?.status == .uploading(progress: 0.75))
    }

    // MARK: - Cancellation

    /// A purposeful cancel forgets the upload outright: it must not linger as a `.cancelled` row,
    /// on disk, or in the persisted store.
    @Test
    func cancel_removesTheUploadEntirely() async throws {
        // Given
        let uploadID = try await enqueueOne()

        // When
        await sut.cancel(uploadID: uploadID)

        // Then
        #expect(session.cancelTaskUploadID_Invocations == [uploadID])
        #expect(!fileCache.deleteStagedFileName_Invocations.isEmpty)
        #expect(store.deleteUploadIDs_Invocations.flatMap(\.self).contains(uploadID))
        #expect(tracker.summary.items.isEmpty)
    }

    /// `.failed` is terminal, but the sheet offers the same xmark on a failed row as on an
    /// in-flight one — tapping it must forget the upload, not silently do nothing.
    @Test
    func cancel_removesAFailedUpload() async throws {
        // Given
        let uploadID = try await enqueueOne()
        await sut.handle([.completed(uploadID: uploadID, statusCode: 400, responseBody: nil, error: nil)])

        // When
        await sut.cancel(uploadID: uploadID)

        // Then
        #expect(store.deleteUploadIDs_Invocations.flatMap(\.self).contains(uploadID))
        #expect(tracker.summary.items.isEmpty)
    }

    /// If the app is force-quit right after the user taps cancel, whatever has not yet reached
    /// disk is lost. The Core Data delete must therefore happen before anything that can stall —
    /// cancelling the task round-trips through `nsurlsessiond`, and staging deletion touches disk —
    /// or a quit at exactly the wrong moment leaves the record behind to be resurrected by
    /// reconciliation on the next launch.
    @Test
    func cancel_removesTheStoreRecordBeforeAnythingElseThatCouldStall() async throws {
        // Given
        let uploadID = try await enqueueOne()

        var order: [String] = []
        store.deleteUploadIDs_MockMethod = { _ in order.append("store") }
        session.cancelTaskUploadID_MockMethod = { _ in order.append("session") }
        fileCache.deleteStagedFileName_MockMethod = { _ in order.append("staging") }

        // When
        await sut.cancel(uploadID: uploadID)

        // Then
        #expect(order.first == "store")
    }

    /// `task.cancel()` reports `NSURLErrorCancelled` asynchronously, after the upload has already
    /// been removed. That late event must not resurrect it as a failure.
    @Test
    func cancel_isNotMistakenForAFailureWhenTheCallbackArrives() async throws {
        // Given
        let uploadID = try await enqueueOne()
        await sut.cancel(uploadID: uploadID)

        // When
        await sut.handle([
            .completed(
                uploadID: uploadID,
                statusCode: nil,
                responseBody: nil,
                error: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
            )
        ])

        // Then
        #expect(tracker.summary.items.isEmpty)
    }

    /// A direct upload always creates a new node, so the node itself is what needs removing.
    @Test
    func cancel_removesThePartiallyCreatedNode() async throws {
        // Given
        let uploadID = try await enqueueOne()

        // When
        await sut.cancel(uploadID: uploadID)
        await sut.waitForPendingWork()

        // Then
        #expect(!nodesAPI.deleteNodesNodeIDsPermanently_Invocations.isEmpty)
    }

    @Test
    func cancel_ignoresAnAlreadyFinishedUpload() async throws {
        // Given
        let uploadID = try await enqueueOne()
        await sut.handle([.completed(uploadID: uploadID, statusCode: 200, responseBody: nil, error: nil)])

        // When
        await sut.cancel(uploadID: uploadID)

        // Then
        let summary = tracker.summary
        #expect(summary.items.first?.status == .uploaded)
    }

    @Test
    func cancelAll_removesEveryUnfinishedUpload() async throws {
        // Given
        _ = try await sut.enqueue(
            sources: [makeSource(named: "a.pdf"), makeSource(named: "b.pdf")],
            destinationFolderPath: "cell-1"
        )
        await sut.waitForPendingWork()

        // When
        await sut.cancelAll()

        // Then
        #expect(session.cancelAllTasks_Invocations.count >= 1)
        #expect(tracker.summary.items.isEmpty)
    }

    // MARK: - Retry

    @Test
    func retry_restartsAFailedUpload() async throws {
        // Given
        let uploadID = try await enqueueOne()
        await sut.handle([.completed(uploadID: uploadID, statusCode: 400, responseBody: nil, error: nil)])
        let uploadsBefore = session.startUploadUploadIDRequestFileURL_Invocations.count

        // When
        await sut.retry(uploadID: uploadID)
        await sut.waitForPendingWork()

        // Then
        #expect(session.startUploadUploadIDRequestFileURL_Invocations.count > uploadsBefore)

        let summary = tracker.summary
        #expect(summary.failedCount == 0)
    }

    @Test
    func retry_failsAgainWhenTheStagedFileIsGone() async throws {
        // Given
        let uploadID = try await enqueueOne()
        await sut.handle([.completed(uploadID: uploadID, statusCode: 400, responseBody: nil, error: nil)])
        fileCache.existsStagedFileName_MockValue = false

        // When
        await sut.retry(uploadID: uploadID)

        // Then
        let summary = tracker.summary
        #expect(summary.items.first?.status == .failed(error: .fileNotFound))
    }

    @Test
    func retry_ignoresAnUploadThatHasNotFailed() async throws {
        // Given
        let uploadID = try await enqueueOne()
        let uploadsBefore = session.startUploadUploadIDRequestFileURL_Invocations.count

        // When
        await sut.retry(uploadID: uploadID)
        await sut.waitForPendingWork()

        // Then
        #expect(session.startUploadUploadIDRequestFileURL_Invocations.count == uploadsBefore)
    }

    @Test
    func retryFailed_restartsEveryRetryableUpload() async throws {
        // Given
        _ = try await sut.enqueue(
            sources: [makeSource(named: "a.pdf"), makeSource(named: "b.pdf")],
            destinationFolderPath: "cell-1"
        )
        await sut.waitForPendingWork()

        let summaryBefore = tracker.summary
        #expect(summaryBefore.items.count == 2)

        for item in summaryBefore.items {
            for _ in 0 ... WireDriveDirectUploadManager.ErrorClassifier.maximumSilentRestarts {
                await sut.handle([
                    .completed(uploadID: item.id, statusCode: 401, responseBody: nil, error: nil)
                ])
                await sut.waitForPendingWork()
            }
        }

        let failedSummary = tracker.summary
        let allRetryable = failedSummary.items.allSatisfy(\.isRetryable)
        #expect(failedSummary.failedCount == 2)
        #expect(allRetryable)

        // When
        await sut.retryFailed()
        await sut.waitForPendingWork()

        // Then
        let summary = tracker.summary
        #expect(summary.failedCount == 0)
    }

    // MARK: - Clearing

    @Test
    func clearFinished_forgetsTerminalUploadsOnly() async throws {
        // Given
        _ = try await sut.enqueue(
            sources: [makeSource(named: "a.pdf"), makeSource(named: "b.pdf")],
            destinationFolderPath: "cell-1"
        )
        await sut.waitForPendingWork()

        let items = tracker.summary.items
        let finished = try #require(items.first)
        await sut.handle([.completed(uploadID: finished.id, statusCode: 200, responseBody: nil, error: nil)])

        // When
        await sut.clearFinished()

        // Then
        let summary = tracker.summary
        #expect(summary.items.count == 1)
        #expect(summary.items.first?.id != finished.id)
        #expect(store.deleteUploadIDs_Invocations.flatMap(\.self).contains(finished.id))
    }

    /// Failed uploads are left in place, since the user can still retry them.
    @Test
    func clearFinished_keepsFailedUploads() async throws {
        // Given
        let failed = WireDriveDirectUploadRecord.fixture(state: .failed, failure: .unauthorized)
        store.fetchAll_MockValue = [failed]
        await sut.start()

        _ = try await sut.enqueue(sources: [makeSource(named: "report.pdf")], destinationFolderPath: "cell-1")
        await sut.waitForPendingWork()
        let uploadedID = try #require(tracker.summary.items.first(where: { $0.id != failed.uploadID })?.id)

        await sut.handle([.completed(uploadID: uploadedID, statusCode: 200, responseBody: nil, error: nil)])

        // When
        await sut.clearFinished()

        // Then
        let summary = tracker.summary
        #expect(summary.items.map(\.id) == [failed.uploadID])
        #expect(summary.items.first?.status == .failed(error: .unauthorized))
    }

    // MARK: - Start

    @Test
    func start_loadsPersistedUploadsAndAttachesToTheSession() async throws {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .failed, failure: .unauthorized)
        store.fetchAll_MockValue = [record]

        // When
        await sut.start()

        // Then
        #expect(session.setEventSink_Invocations.count == 1)

        let summary = tracker.summary
        #expect(summary.items.map(\.id) == [record.uploadID])
        #expect(summary.items.first?.status == .failed(error: .unauthorized))
    }

    @Test
    func start_isIdempotent() async {
        // When
        await sut.start()
        await sut.start()

        // Then
        #expect(session.setEventSink_Invocations.count == 1)
    }

    @Test
    func start_sweepsOrphanedStagedFiles() async {
        // When
        await sut.start()

        // Then
        #expect(!fileCache.sweepOrphansReferencedFileNamesGracePeriod_Invocations.isEmpty)
    }

    /// The force-quit case: iOS cancelled the task and delivered nothing. The backend is asked
    /// before re-sending, so an upload that already arrived is not sent twice.
    @Test
    func start_marksAnUploadThatCompletedWhileTheAppWasDeadAsUploaded() async throws {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .uploading)
        store.fetchAll_MockValue = [record]
        session.currentTasks_MockValue = []
        nodesAPI.getNodeNodeID_MockValue = WireDriveNode(uuid: record.nodeID, path: record.nodePath)
        nodesAPI.getVersionsNodeID_MockValue = [
            WireDriveNodeVersion(
                id: record.versionID,
                ownerName: nil,
                modified: nil,
                eTag: nil,
                size: nil,
                downloadUrl: nil
            )
        ]

        // When
        await sut.start()
        await sut.waitForPendingWork()

        // Then
        let summary = tracker.summary
        #expect(summary.items.first?.status == .uploaded)
    }

    @Test
    func start_restartsAnUploadThatNeverReachedTheBackend() async throws {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .uploading)
        store.fetchAll_MockValue = [record]
        session.currentTasks_MockValue = []
        nodesAPI.getNodeNodeID_MockError = URLError(.resourceUnavailable)

        // When
        await sut.start()
        await sut.waitForPendingWork()

        // Then
        #expect(session.startUploadUploadIDRequestFileURL_Invocations.count == 1)
    }

    /// The ordinary suspend-and-resume case: the transfer survived and must not restart.
    @Test
    func start_adoptsASurvivingTransfer() async throws {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .uploading)
        store.fetchAll_MockValue = [record]
        session.currentTasks_MockValue = [
            .fixture(
                uploadID: record.uploadID,
                taskIdentifier: 11,
                state: .running,
                bytesSent: 1024,
                totalBytes: 2048
            )
        ]

        // When
        await sut.start()
        await sut.waitForPendingWork()

        // Then
        #expect(session.startUploadUploadIDRequestFileURL_Invocations.isEmpty)

        let summary = tracker.summary
        #expect(summary.items.first?.status == .uploading(progress: 0.5))
    }

    @Test
    func start_cancelsATaskThatNoRecordClaims() async {
        // Given
        store.fetchAll_MockValue = []
        session.currentTasks_MockValue = [.fixture(uploadID: UUID(), taskIdentifier: 77, state: .running)]

        // When
        await sut.start()

        // Then
        #expect(session.cancelTaskTaskIdentifier_Invocations == [77])
    }

    @Test
    func start_failsAnUploadWhoseStagedFileIsGone() async throws {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .uploading)
        store.fetchAll_MockValue = [record]
        fileCache.existsStagedFileName_MockValue = false

        // When
        await sut.start()

        // Then
        let summary = tracker.summary
        #expect(summary.items.first?.status == .failed(error: .fileNotFound))
    }

    // MARK: - Tear down

    @Test
    func tearDown_removesEverything() async throws {
        // Given
        _ = try await enqueueOne()

        // When
        await sut.tearDown()

        // Then
        #expect(session.cancelAllTasks_Invocations.count >= 1)
        #expect(store.deleteAll_Invocations.count == 1)

        let summary = tracker.summary
        #expect(summary.items.isEmpty)
    }

    // MARK: - Observing

    /// The tracker sheet is global to the drive session and outlives folder navigation, so a view
    /// that subscribes after an upload has already started must still see it.
    @Test
    func summaryPublisherReplaysCurrentStateToALateSubscriber() async throws {
        // Given
        _ = try await enqueueOne()

        // When
        var received: WireDriveDirectUploadsSummary?
        let subscription = tracker.summaryPublisher.sink { received = $0 }
        defer { subscription.cancel() }

        // Then
        let summary = try #require(received)
        #expect(summary.items.count == 1)
    }

    @Test
    func perUploadPublisherEmitsNilOnceTheUploadIsForgotten() async throws {
        // Given
        let uploadID = try await enqueueOne()
        await sut.handle([.completed(uploadID: uploadID, statusCode: 200, responseBody: nil, error: nil)])

        var received: [WireDriveDirectUploadItem?] = []
        let subscription = tracker.publisher(uploadID: uploadID).sink { received.append($0) }
        defer { subscription.cancel() }

        // When
        await sut.clearFinished()

        // Then
        #expect(received.last ?? .some(nil) == nil)
    }

    @Test
    func folderPublisherFiltersByDestination() async throws {
        // Given
        _ = try await sut.enqueue(sources: [makeSource(named: "a.pdf")], destinationFolderPath: "cell-1/Documents")
        _ = try await sut.enqueue(sources: [makeSource(named: "b.pdf")], destinationFolderPath: "cell-1/Photos")
        await sut.waitForPendingWork()

        // When
        var received: [WireDriveDirectUploadItem]?
        let subscription = tracker.publisher(folderPath: "cell-1/Documents").sink { received = $0 }
        defer { subscription.cancel() }

        // Then
        #expect(received?.map(\.fileName) == ["a.pdf"])
    }

    /// The sheet re-subscribes to wherever the user is currently browsing, so a subfolder's uploads
    /// must not also show while looking at its parent — the mechanism is a single instance shared
    /// across every open conversation, so exact matching is also what keeps a sibling conversation
    /// whose cell name happens to share a prefix from leaking in.
    @Test
    func folderPublisherExcludesSubfoldersAndUnrelatedConversations() async throws {
        // Given
        _ = try await sut.enqueue(sources: [makeSource(named: "a.pdf")], destinationFolderPath: "cell-1")
        _ = try await sut.enqueue(sources: [makeSource(named: "b.pdf")], destinationFolderPath: "cell-1/Documents")
        _ = try await sut.enqueue(sources: [makeSource(named: "c.pdf")], destinationFolderPath: "cell-10")
        await sut.waitForPendingWork()

        // When
        var received: [WireDriveDirectUploadItem]?
        let subscription = tracker.publisher(folderPath: "cell-1").sink { received = $0 }
        defer { subscription.cancel() }

        // Then
        #expect(received?.map(\.fileName) == ["a.pdf"])
    }

    /// A stream that emitted on every progress tick would be pointless; `removeDuplicates` is what
    /// makes the tracker cheap to observe.
    @Test
    func summaryPublisherDoesNotEmitWhenNothingChanged() async throws {
        // Given
        _ = try await enqueueOne()

        var emissions = 0
        let subscription = tracker.summaryPublisher.sink { _ in emissions += 1 }
        defer { subscription.cancel() }

        // When — re-enqueuing nothing is a no-op on the tracked state.
        await sut.waitForPendingWork()

        // Then — only the replayed value.
        #expect(emissions == 1)
    }

    // MARK: - Helpers

    private func enqueueOne() async throws -> UUID {
        _ = try await sut.enqueue(sources: [makeSource(named: "report.pdf")], destinationFolderPath: "cell-1")
        await sut.waitForPendingWork()
        let items = tracker.summary.items
        return try #require(items.first?.id)
    }

    private func makeSource(named fileName: String) -> WireDriveDirectUploadSource {
        WireDriveDirectUploadSource(
            url: URL(fileURLWithPath: "/tmp/source/\(fileName)"),
            fileName: fileName,
            fileType: .pdf
        )
    }
}

/// Lets a test suspend a mocked async call until it explicitly releases it, to make a race between
/// two concurrent operations deterministic instead of timing-based.
private actor AsyncGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}
