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

package import Combine
package import Foundation
import WireLogging
package import WireMessagingDomain

/// Drives Wire Drive direct uploads: stage the bytes, pre-check the destination path, mint a
/// presigned `PUT` URL, hand it to the background session, then mark the upload done. Tasks are
/// created up front rather than lazily, since pre-checking and presigning need the app running.
///
/// Split across three files by concern: this one holds the pipeline and public API, while relaunch
/// recovery and transfer-outcome handling live in `+Reconciler` and `+ErrorClassifier`.

@MainActor
package final class WireDriveDirectUploadManager:
    WireDriveDirectUploadManagerProtocol,
    @unchecked Sendable {

    enum Constants {
        static let maximumPresignedURLLifetime: TimeInterval = 12 * 60 * 60
        static let minimumPresignedURLLifetime: TimeInterval = 60

        /// How long to wait for a completion callback the session says has already happened.
        static let completionWatchdog: TimeInterval = 10

        static let orphanSweepGracePeriod: TimeInterval = 60 * 60

        /// Pre-check and presign concurrency.
        static let maxConcurrentPreparations = 4

        /// A ceiling on uploads with work left to do, as a backstop against a retry-all storm.
        static let maxActiveUploads = 60
    }

    // MARK: - Dependencies

    let nodesAPI: any NodesAPIProtocol
    private let store: any WireDriveDirectUploadStoreProtocol
    let fileCache: any WireDriveDirectUploadFileCacheProtocol
    let session: any WireDriveDirectUploadSessionProtocol
    private let accessTokenProvider: any AccessTokenProvider
    let tracker: any WireDriveDirectUploadTrackerProtocol
    let classifier: ErrorClassifier
    let reconciler: Reconciler
    /// Backoff before automatic retries, indexed by attempt. Injectable so tests need not sleep.
    let retryBackoff: [TimeInterval]
    private let now: @Sendable () -> Date

    // MARK: - State

    /// The authoritative in-memory view of every tracked upload.
    var records: [UUID: WireDriveDirectUploadRecord] = [:]

    /// Live progress, keyed by upload. Never persisted.
    var progress: [UUID: Float] = [:]

    private var didStart = false

    package init(
        nodesAPI: any NodesAPIProtocol,
        store: any WireDriveDirectUploadStoreProtocol,
        fileCache: any WireDriveDirectUploadFileCacheProtocol,
        session: any WireDriveDirectUploadSessionProtocol,
        accessTokenProvider: any AccessTokenProvider,
        tracker: any WireDriveDirectUploadTrackerProtocol,
        classifier: ErrorClassifier = .init(),
        reconciler: Reconciler = .init(),
        retryBackoff: [TimeInterval] = [2, 8],
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.nodesAPI = nodesAPI
        self.store = store
        self.fileCache = fileCache
        self.session = session
        self.accessTokenProvider = accessTokenProvider
        self.tracker = tracker
        self.classifier = classifier
        self.reconciler = reconciler
        self.retryBackoff = retryBackoff
        self.now = now
    }

    // MARK: - Deferred work

    private struct DeferredWorkEntry {
        let token: UUID
        let task: Task<Void, Never>
    }

    private var deferredWork: [UUID: DeferredWorkEntry] = [:]

    func scheduleDeferred(_ key: UUID, operation: @escaping @Sendable () async -> Void) {
        deferredWork[key]?.task.cancel()
        let token = UUID()
        let task = Task { [weak self] in
            await operation()
            self?.clearDeferredWork(key, token: token)
        }
        deferredWork[key] = DeferredWorkEntry(token: token, task: task)
    }

    private func clearDeferredWork(_ key: UUID, token: UUID) {
        guard deferredWork[key]?.token == token else { return }
        deferredWork[key] = nil
    }

    package func waitForPendingWork() async {
        while !deferredWork.isEmpty {
            let tasks = deferredWork.values.map(\.task)
            deferredWork = [:]
            for task in tasks {
                await task.value
            }
        }
    }

    // MARK: - Lifecycle

    package func start() async {
        guard !didStart else { return }
        let persisted: [WireDriveDirectUploadRecord]
        do {
            persisted = try await store.fetchAll()
        } catch {
            WireLogger.wireDrive.error("failed to load persisted drive uploads, deferring start: \(error)")
            return
        }

        didStart = true

        for record in persisted where records[record.uploadID] == nil {
            records[record.uploadID] = record
        }

        publishToTracker(replacingAll: true)

        // Buffered events predate any task snapshot, so they must be applied first or a completed
        // upload could be restarted.
        await session.setEventSink(self)

        await reconcile()
        sweepOrphanedStagedFiles()
    }

    package func tearDown() async {
        await session.cancelAllTasks()
        await session.removeEventSink()

        for record in records.values {
            try? fileCache.delete(stagedFileName: record.stagedFileName)
        }

        records = [:]
        progress = [:]
        try? await store.deleteAll()
        tracker.removeAll()
    }

    // MARK: - Enqueuing

    @discardableResult
    package func enqueue(
        sources: [WireDriveDirectUploadSource],
        destinationFolderPath: String
    ) async throws -> UUID {
        guard !sources.isEmpty else {
            throw WireDriveDirectUploadBatchError.noFiles
        }

        guard activeRecords.count + sources.count <= WireDriveDirectUploadLimits.maxFilesPerBatch else {
            throw WireDriveDirectUploadBatchError.tooManyFiles(limit: WireDriveDirectUploadLimits.maxFilesPerBatch)
        }

        let batchID = UUID()
        var staged: [WireDriveDirectUploadRecord] = []

        for source in sources {
            let uploadID = UUID()
            let fileName = WireDriveNodeNameSanitizer.sanitize(source.fileName)

            do {
                let stagedFile = try await fileCache.stage(
                    sourceURL: source.url,
                    uploadID: uploadID,
                    fileName: fileName,
                    isSecurityScoped: source.isSecurityScoped
                )

                let timestamp = now()
                staged.append(
                    WireDriveDirectUploadRecord(
                        uploadID: uploadID,
                        batchID: batchID,
                        nodeID: UUID(),
                        versionID: UUID(),
                        destinationFolderPath: destinationFolderPath,
                        nodePath: [destinationFolderPath, fileName].joined(separator: "/"),
                        fileName: fileName,
                        fileSize: stagedFile.size,
                        mimeType: source.fileType?.preferredMIMEType,
                        stagedFileName: stagedFile.fileName,
                        state: .staged,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                )
            } catch {
                for record in staged {
                    try? fileCache.delete(stagedFileName: record.stagedFileName)
                }
                WireLogger.wireDrive.error("failed to stage drive upload: \(error)")
                throw WireDriveDirectUploadBatchError.stagingFailed(
                    fileName: source.fileName,
                    message: "\(error)"
                )
            }
        }

        let admitted = admissible(candidates: staged)

        for record in admitted {
            records[record.uploadID] = record
        }

        try? await store.upsert(records: admitted)
        publishToTracker()

        if admitted.count < staged.count {
            let dropped = staged.count - admitted.count
            WireLogger.wireDrive.warn(
                "drive upload batch truncated: \(dropped) file(s) exceeded the active upload ceiling"
            )
        }

        let uploadIDs = admitted.map(\.uploadID)
        scheduleDeferred(batchID) { [weak self] in
            await self?.prepareAndStart(uploadIDs: uploadIDs)
        }

        return batchID
    }

    // MARK: - User actions

    package func cancel(uploadID: UUID) async {
        guard let record = records[uploadID], record.state != .uploaded, record.state != .cancelled else { return }

        records[uploadID] = nil
        progress[uploadID] = nil

        do {
            try await store.delete(uploadIDs: [uploadID])
        } catch {
            WireLogger.wireDrive.error("failed to remove cancelled drive upload from storage: \(error)")
        }

        await session.cancelTask(uploadID: uploadID)
        try? fileCache.delete(stagedFileName: record.stagedFileName)

        if record.state.hasRemoteState {
            let nodeID = record.nodeID
            let nodesAPI = nodesAPI
            scheduleDeferred(UUID()) {
                do {
                    _ = try await nodesAPI.deleteNodes(nodeIDs: [nodeID], permanently: true)
                } catch {
                    WireLogger.wireDrive.info("could not remove cancelled drive upload node: \(error)")
                }
            }
        }

        publishToTracker(replacingAll: true)
    }

    package func cancelAll() async {
        let cancellable = records.values.filter { !$0.state.isTerminal }.map(\.uploadID)
        guard !cancellable.isEmpty else { return }

        await session.cancelAllTasks()

        for uploadID in cancellable {
            await cancel(uploadID: uploadID)
        }
    }

    package func retry(uploadID: UUID) async {
        guard let record = records[uploadID], record.state == .failed else { return }
        guard fileCache.exists(stagedFileName: record.stagedFileName) else {
            await handleFailure(uploadID: uploadID, error: .fileNotFound)
            return
        }

        await transition(uploadID: uploadID) {
            $0.state = .preChecked
            $0.failure = nil
            $0.attemptCount = 0
            $0.presignedURL = nil
            $0.presignedURLExpiresAt = nil
            $0.taskIdentifier = nil
        }

        publishToTracker()
        await prepareAndStart(uploadIDs: [uploadID])
    }

    package func retryFailed() async {
        let retryable = records.values
            .filter { $0.state == .failed && ($0.failure?.isRetryable ?? true) }
            .map(\.uploadID)

        for uploadID in retryable {
            await retry(uploadID: uploadID)
        }
    }

    /// Forgets uploads that finished successfully or were cancelled.
    ///
    /// Failed uploads are deliberately kept: they are still retryable, and forgetting them would
    /// take that away without the user asking for it.
    package func clearFinished() async {
        let finished = records.values.filter { $0.state == .uploaded || $0.state == .cancelled }
        guard !finished.isEmpty else { return }

        for record in finished {
            try? fileCache.delete(stagedFileName: record.stagedFileName)
            records[record.uploadID] = nil
            progress[record.uploadID] = nil
        }

        try? await store.delete(uploadIDs: finished.map(\.uploadID))
        publishToTracker(replacingAll: true)
    }

    // MARK: - Helpers

    private var activeRecords: [WireDriveDirectUploadRecord] {
        records.values.filter { !$0.state.isTerminal }
    }

    /// The prefix of `candidates` that fits within the active upload ceiling, oldest first.

    private func admissible(candidates: [WireDriveDirectUploadRecord]) -> [WireDriveDirectUploadRecord] {
        let capacity = max(0, Constants.maxActiveUploads - activeRecords.count)
        guard capacity > 0 else { return [] }

        return candidates
            .sorted { $0.createdAt < $1.createdAt }
            .prefix(capacity)
            .map(\.self)
    }

    /// Applies a change to a record, in memory and in the store. The store skips the write when
    /// nothing durable changed, so callers do not have to reason about write amplification.
    func transition(
        uploadID: UUID,
        _ mutate: (inout WireDriveDirectUploadRecord) -> Void
    ) async {
        guard var record = records[uploadID] else { return }

        mutate(&record)
        record.updatedAt = now()
        records[uploadID] = record

        do {
            try await store.upsert(record)
        } catch {
            WireLogger.wireDrive.error("failed to persist drive upload transition: \(error)")
        }
    }

    /// Runs a throwing operation, routing any failure through `handleFailure` and returning `nil`.
    private func attempt<T>(uploadID: UUID, operation: () async throws -> T) async -> T? {
        do {
            return try await operation()
        } catch {
            await handleFailure(uploadID: uploadID, error: WireDriveUploadError(error))
            return nil
        }
    }

    func clampedFraction(_ sent: Int64, of total: Int64) -> Float {
        min(max(Float(sent) / Float(total), 0), 1)
    }

    func publishToTracker(replacingAll: Bool = false) {
        let items = records.values.map { record in
            record.toItem(
                progress: progress[record.uploadID],
                isStagedFileAvailable: fileCache.exists(stagedFileName: record.stagedFileName)
            )
        }

        if replacingAll {
            tracker.replaceAll(with: items)
        } else {
            tracker.upsert(items)
        }
    }

    private func sweepOrphanedStagedFiles() {
        let referenced = Set(records.values.map(\.stagedFileName))
        do {
            try fileCache.sweepOrphans(
                referencedFileNames: referenced,
                gracePeriod: Constants.orphanSweepGracePeriod
            )
        } catch {
            WireLogger.wireDrive.warn("failed to sweep orphaned staged upload files: \(error)")
        }
    }

}

// MARK: - Pipeline

extension WireDriveDirectUploadManager {

    /// Takes uploads from wherever they are up to, through to a running transfer.
    func prepareAndStart(uploadIDs: [UUID]) async {
        await withTaskGroup(of: Void.self) { group in
            var running = 0

            for uploadID in uploadIDs {
                guard let record = records[uploadID] else { continue }

                if record.state == .staged {
                    await runPreCheck(uploadID: uploadID)
                }

                guard let prepared = records[uploadID],
                      prepared.state == .preChecked || prepared.state == .awaitingStart
                else { continue }

                if running == Constants.maxConcurrentPreparations {
                    await group.next()
                    running -= 1
                }

                running += 1
                group.addTask { await self.presignAndStart(uploadID: uploadID) }
            }
        }

        publishToTracker()
    }

    private func runPreCheck(uploadID: UUID) async {
        guard let record = records[uploadID] else { return }

        guard let result = await attempt(uploadID: uploadID, operation: {
            try await nodesAPI.preCheck(nodePath: record.nodePath, findAvailablePath: true)
        }) else { return }

        let resolvedPath = switch result {
        case let .fileExists(nextPath): nextPath
        case .success: record.nodePath
        }

        await transition(uploadID: uploadID) {
            $0.nodePath = resolvedPath
            $0.state = .preChecked
        }
    }

    private func presignAndStart(uploadID: UUID) async {
        guard let record = records[uploadID] else { return }

        if record.needsPresignedURL(now: now()) {
            guard let url = await attempt(uploadID: uploadID, operation: {
                try await presignedUploadURL(for: record)
            }) else { return }

            await transition(uploadID: uploadID) {
                $0.presignedURL = url.url
                $0.presignedURLExpiresAt = url.expiresAt
                $0.state = .awaitingStart
            }
        }

        await startTask(uploadID: uploadID)
    }

    private func presignedUploadURL(for record: WireDriveDirectUploadRecord) async throws
        -> (url: URL, expiresAt: Date) {
        let token = try await accessTokenProvider.accessToken()
        let remaining = token.expirationDate.timeIntervalSince(now())
        let lifetime = min(
            max(remaining, Constants.minimumPresignedURLLifetime),
            Constants.maximumPresignedURLLifetime
        )

        let node = WireDriveNode(
            uuid: record.nodeID,
            path: record.nodePath,
            size: record.fileSize,
            isDraft: true,
            mimeType: record.mimeType
        )

        let url = try await nodesAPI.presignedUploadURL(
            node: node,
            versionID: record.versionID,
            expiration: lifetime
        )

        return (url, now().addingTimeInterval(lifetime))
    }

    private func startTask(uploadID: UUID) async {
        guard let record = records[uploadID], let presignedURL = record.presignedURL else { return }

        guard fileCache.exists(stagedFileName: record.stagedFileName) else {
            await handleFailure(uploadID: uploadID, error: .fileNotFound)
            return
        }

        var request = URLRequest(url: presignedURL)
        request.httpMethod = "PUT"

        for (field, value) in record.presignedRequestHeaders {
            request.setValue(value, forHTTPHeaderField: field)
        }

        guard let taskIdentifier = await attempt(uploadID: uploadID, operation: {
            try session.startUpload(
                uploadID: uploadID,
                request: request,
                fileURL: fileCache.url(stagedFileName: record.stagedFileName)
            )
        }) else { return }

        await transition(uploadID: uploadID) {
            $0.state = .uploading
            $0.taskIdentifier = taskIdentifier
            $0.sessionIdentifier = self.session.identifier
            $0.attemptCount += 1
        }
    }

    func handleFailure(uploadID: UUID, error: WireDriveUploadError) async {
        await transition(uploadID: uploadID) {
            $0.state = .failed
            $0.failure = error
            $0.taskIdentifier = nil
        }

        progress[uploadID] = nil
        publishToTracker()
    }
}

// MARK: - WireDriveDirectUploadEventSink

extension WireDriveDirectUploadManager: WireDriveDirectUploadEventSink {

    package func handle(_ events: [WireDriveDirectUploadSessionEvent]) async {
        for event in events {
            switch event {
            case let .progress(uploadID, bytesSent, totalBytes):
                await handleProgress(uploadID: uploadID, bytesSent: bytesSent, totalBytes: totalBytes)

            case let .completed(uploadID, statusCode, responseBody, error):
                await handleCompletion(
                    uploadID: uploadID,
                    statusCode: statusCode,
                    responseBody: responseBody,
                    error: error
                )
            }
        }
    }

    private func handleProgress(uploadID: UUID, bytesSent: Int64, totalBytes: Int64) async {
        guard let record = records[uploadID], !record.state.isTerminal else { return }
        guard totalBytes > 0 else { return }

        let fraction = max(progress[uploadID] ?? 0, clampedFraction(bytesSent, of: totalBytes))
        progress[uploadID] = fraction

        // Never persisted — straight to the tracker.
        tracker.updateProgress(uploadID: uploadID, progress: fraction)
    }
}
