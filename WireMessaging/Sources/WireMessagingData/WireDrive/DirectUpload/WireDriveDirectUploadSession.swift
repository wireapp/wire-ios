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
import os
import WireLogging

/// A background `URLSession` dedicated to Wire Drive direct uploads, doubling as its own delegate
/// since the session retains it. It must survive relaunches to buffer callbacks that can arrive
/// before the account and database are ready.
///
/// - Important: Exactly one instance may exist per session identifier per process — obtain it via
///   `WireDriveDirectUploadSessionHolder`.

package final class WireDriveDirectUploadSession: NSObject, WireDriveDirectUploadSessionProtocol, @unchecked Sendable {

    private enum Constants {
        static let maximumBufferedEvents = 2000
        static let maximumResponseBodyBytes = 8 * 1024
    }

    package struct ProgressThrottle: Sendable, Equatable {

        private let minimumByteDelta: Int64
        private let minimumInterval: TimeInterval

        private var lastForwardedBytes: Int64?
        private var lastForwardedAt: Date?

        package init(minimumByteDelta: Int64 = 64 * 1024, minimumInterval: TimeInterval = 0.25) {
            self.minimumByteDelta = minimumByteDelta
            self.minimumInterval = minimumInterval
        }

        package mutating func shouldForward(bytesSent: Int64, totalBytes: Int64, now: Date) -> Bool {
            guard shouldForward(bytesSent: bytesSent, totalBytes: totalBytes, at: now) else {
                return false
            }

            lastForwardedBytes = bytesSent
            lastForwardedAt = now
            return true
        }

        private func shouldForward(bytesSent: Int64, totalBytes: Int64, at now: Date) -> Bool {
            // The body has been fully sent: never withhold this one.
            if totalBytes > 0, bytesSent >= totalBytes {
                return true
            }

            guard let lastForwardedBytes, let lastForwardedAt else {
                return true
            }

            // Scale the byte threshold with file size, so a large file emits roughly 100 updates
            // rather than one every 64 KiB.
            let threshold = totalBytes > 0 ? max(minimumByteDelta, totalBytes / 100) : minimumByteDelta

            return bytesSent - lastForwardedBytes >= threshold
                || now.timeIntervalSince(lastForwardedAt) >= minimumInterval
        }
    }

    private struct FlushBatch {
        let sink: (any WireDriveDirectUploadEventSink)?
        let events: [WireDriveDirectUploadSessionEvent]
    }

    private struct State {
        var sink: (any WireDriveDirectUploadEventSink)?
        var buffer: [WireDriveDirectUploadSessionEvent] = []
        var throttles: [Int: ProgressThrottle] = [:]
        var responseBodies: [Int: Data] = [:]
        var isFlushing = false
        var didFinishEventsHandler: (@Sendable (String) -> Void)?
        var droppedProgressEvents = 0
    }

    package let identifier: String
    private var session: URLSession!
    private let lock = OSAllocatedUnfairLock<State>(initialState: .init())

    package init(identifier: String, sharedContainerIdentifier: String?) {
        self.identifier = identifier
        super.init()

        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        // Lets `nsurlsessiond` read the staged files, and relaunch the app when transfers finish.
        configuration.sharedContainerIdentifier = sharedContainerIdentifier
        configuration.sessionSendsLaunchEvents = true
        // These uploads are user initiated: the system must not defer them to a convenient moment.
        configuration.isDiscretionary = false
        configuration.allowsCellularAccess = true
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForResource = 7 * 24 * 60 * 60
        configuration.timeoutIntervalForRequest = configuration.timeoutIntervalForResource
        configuration.httpMaximumConnectionsPerHost = 20

        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    package func setDidFinishEventsHandler(_ handler: @escaping @Sendable (String) -> Void) {
        lock.withLock { $0.didFinishEventsHandler = handler }
    }

    @discardableResult
    package func startUpload(uploadID: UUID, request: URLRequest, fileURL: URL) throws -> Int {
        // A background session accepts only a file body. Neither `uploadTask(with:from:)` nor a
        // stream body is permitted, which is the reason files are staged at all.
        let task = session.uploadTask(with: request, fromFile: fileURL)
        // The only correlation that survives a relaunch. `taskIdentifier` cannot serve here: it is
        // unique only within a session, and is reused once a task is removed.
        task.taskDescription = uploadID.uuidString
        task.resume()

        return task.taskIdentifier
    }

    package func currentTasks() async -> [WireDriveDirectUploadTaskSnapshot] {
        await session.allTasks.map(\.toSnapshot)
    }

    package func cancelTask(uploadID: UUID) async {
        let identifier = uploadID.uuidString
        for task in await session.allTasks where task.taskDescription == identifier {
            task.cancel()
        }
    }

    package func cancelTask(taskIdentifier: Int) async {
        for task in await session.allTasks where task.taskIdentifier == taskIdentifier {
            task.cancel()
        }
    }

    package func cancelAllTasks() async {
        for task in await session.allTasks {
            task.cancel()
        }
    }

    package func setEventSink(_ sink: any WireDriveDirectUploadEventSink) async {
        lock.withLock { $0.sink = sink }
        scheduleFlush()
    }

    package func removeEventSink() async {
        lock.withLock { $0.sink = nil }
    }

    package func invalidate() async {
        WireLogger.wireDrive.info("invalidating drive upload session")
        session.invalidateAndCancel()
    }

    // MARK: - Event buffering

    private func enqueue(_ event: WireDriveDirectUploadSessionEvent) {
        lock.withLock { state in
            if state.buffer.count >= Constants.maximumBufferedEvents {
                if let index = state.buffer.firstIndex(where: \.isProgress) {
                    state.buffer.remove(at: index)
                    state.droppedProgressEvents += 1
                } else if event.isProgress {
                    // Nothing but completions buffered, and this is only progress: drop it.
                    state.droppedProgressEvents += 1
                    return
                } else {
                    // All completions. Growing past the cap is the lesser evil.
                    WireLogger.wireDrive.warn(
                        "drive upload event buffer exceeded its cap with no progress events to shed"
                    )
                }
            }

            state.buffer.append(event)
        }

        scheduleFlush()
    }

    /// Drains the buffer to the sink, one batch at a time.
    private func scheduleFlush() {
        let shouldStart = lock.withLock { state -> Bool in
            guard state.sink != nil, !state.buffer.isEmpty, !state.isFlushing else { return false }
            state.isFlushing = true
            return true
        }

        guard shouldStart else { return }

        Task { [weak self] in
            await self?.flush()
        }
    }

    private func flush() async {
        while true {
            let batch = lock.withLock { state -> FlushBatch in
                guard let sink = state.sink, !state.buffer.isEmpty else {
                    state.isFlushing = false
                    return FlushBatch(sink: nil, events: [])
                }

                let events = state.buffer
                state.buffer = []
                return FlushBatch(sink: sink, events: events)
            }

            guard let sink = batch.sink, !batch.events.isEmpty else { return }

            await sink.handle(batch.events)
        }
    }

    private func uploadID(of task: URLSessionTask) -> UUID? {
        task.taskDescription.flatMap(UUID.init(uuidString:))
    }
}

// MARK: - URLSessionDataDelegate

extension WireDriveDirectUploadSession: URLSessionDataDelegate {

    package func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        guard let uploadID = uploadID(of: task) else { return }

        let shouldForward = lock.withLock { state -> Bool in
            var throttle = state.throttles[task.taskIdentifier] ?? ProgressThrottle()
            let result = throttle.shouldForward(
                bytesSent: totalBytesSent,
                totalBytes: totalBytesExpectedToSend,
                now: Date()
            )
            state.throttles[task.taskIdentifier] = throttle
            return result
        }

        guard shouldForward else { return }

        enqueue(
            .progress(
                uploadID: uploadID,
                bytesSent: totalBytesSent,
                totalBytes: totalBytesExpectedToSend
            )
        )
    }

    package func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.withLock { state in
            var body = state.responseBodies[dataTask.taskIdentifier] ?? Data()
            guard body.count < Constants.maximumResponseBodyBytes else { return }
            body.append(data.prefix(Constants.maximumResponseBodyBytes - body.count))
            state.responseBodies[dataTask.taskIdentifier] = body
        }
    }

    package func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        let responseBody = lock.withLock { state in
            state.throttles.removeValue(forKey: task.taskIdentifier)
            return state.responseBodies.removeValue(forKey: task.taskIdentifier)
        }

        guard let uploadID = uploadID(of: task) else {
            WireLogger.wireDrive.warn("drive upload task completed without an upload identifier")
            return
        }

        enqueue(
            .completed(
                uploadID: uploadID,
                statusCode: (task.response as? HTTPURLResponse)?.statusCode,
                responseBody: responseBody,
                error: error as NSError?
            )
        )
    }

    package func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard let identifier = session.configuration.identifier else { return }

        let handler = lock.withLock(\.didFinishEventsHandler)
        handler?(identifier)
    }
}

private extension URLSessionTask {

    var toSnapshot: WireDriveDirectUploadTaskSnapshot {
        WireDriveDirectUploadTaskSnapshot(
            uploadID: taskDescription.flatMap(UUID.init(uuidString:)),
            taskIdentifier: taskIdentifier,
            state: state.toSnapshotState,
            bytesSent: countOfBytesSent,
            totalBytes: countOfBytesExpectedToSend,
            originalURL: originalRequest?.url
        )
    }
}

private extension URLSessionTask.State {

    var toSnapshotState: WireDriveDirectUploadTaskSnapshot.State {
        switch self {
        case .running: .running
        case .suspended: .suspended
        case .canceling: .canceling
        case .completed: .completed
        @unknown default: .completed
        }
    }
}

// sourcery: AutoMockable
package protocol WireDriveDirectUploadSessionProtocol: Sendable {

    var identifier: String { get }

    /// Creates and starts an upload task, tagging it with `uploadID`.
    @discardableResult
    func startUpload(uploadID: UUID, request: URLRequest, fileURL: URL) throws -> Int

    /// Every task the session still knows about, including ones restored after a relaunch.

    func currentTasks() async -> [WireDriveDirectUploadTaskSnapshot]

    func cancelTask(uploadID: UUID) async

    /// Cancels a task that carries no upload identifier.
    func cancelTask(taskIdentifier: Int) async

    func cancelAllTasks() async

    func setEventSink(_ sink: any WireDriveDirectUploadEventSink) async

    func removeEventSink() async

    /// Cancels everything and makes the session unusable. Only for logout.

    func invalidate() async
}

/// What the session knows about a task at a point in time.
package struct WireDriveDirectUploadTaskSnapshot: Sendable, Equatable {

    package enum State: Sendable, Equatable {
        case running
        case suspended
        case canceling
        case completed
    }

    package let uploadID: UUID?
    package let taskIdentifier: Int
    package let state: State
    package let bytesSent: Int64
    package let totalBytes: Int64
    package let originalURL: URL?

    package init(
        uploadID: UUID?,
        taskIdentifier: Int,
        state: State,
        bytesSent: Int64,
        totalBytes: Int64,
        originalURL: URL?
    ) {
        self.uploadID = uploadID
        self.taskIdentifier = taskIdentifier
        self.state = state
        self.bytesSent = bytesSent
        self.totalBytes = totalBytes
        self.originalURL = originalURL
    }

    /// Whether the task is still expected to make progress.

    package var isActive: Bool {
        switch state {
        case .running, .suspended: true
        case .canceling, .completed: false
        }
    }
}

// MARK: - Events

/// Something the background `URLSession` reported about an upload.

package enum WireDriveDirectUploadSessionEvent: Sendable, Equatable {

    case progress(uploadID: UUID, bytesSent: Int64, totalBytes: Int64)
    case completed(uploadID: UUID, statusCode: Int?, responseBody: Data?, error: NSError?)

    package var uploadID: UUID {
        switch self {
        case let .progress(uploadID, _, _): uploadID
        case let .completed(uploadID, _, _, _): uploadID
        }
    }

    package var isProgress: Bool {
        switch self {
        case .progress: true
        case .completed: false
        }
    }
}

package protocol WireDriveDirectUploadEventSink: AnyObject, Sendable {
    func handle(_ events: [WireDriveDirectUploadSessionEvent]) async
}
