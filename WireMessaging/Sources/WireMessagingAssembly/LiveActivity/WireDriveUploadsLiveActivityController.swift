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
import WireDriveUploadsLiveActivity
import WireLogging
import WireMessagingDomain

/// Keeps a Live Activity in step with the ongoing Wire Drive direct uploads.
@MainActor
final class WireDriveUploadsLiveActivityController {

    enum Constants {
        /// How long an activity of finished uploads stays up when nothing went wrong.
        static let completedDismissalDelay: TimeInterval = 4
    }

    private let observeUploads: any WireDriveObserveDirectUploadsUseCaseProtocol
    private let client: any WireDriveUploadsActivityClient
    private let now: () -> Date
    private let delay: @Sendable (TimeInterval) async -> Void
    private var throttle: WireDriveUploadsActivityThrottle
    private var subscription: AnyCancellable?
    private var pendingWork: Task<Void, Never>?
    /// Ends the activity of finished uploads once it has been up long enough.
    private var pendingEnd: Task<Void, Never>?
    private var latestSummary: WireDriveDirectUploadsSummary?

    /// Whether uploads have been seen by this process. The tracker starts out empty and only learns about
    /// persisted uploads once the manager has started, so an empty summary means nothing before that.
    private var hasSeenUploads = false

    init(
        observeUploads: any WireDriveObserveDirectUploadsUseCaseProtocol,
        client: any WireDriveUploadsActivityClient,
        throttle: WireDriveUploadsActivityThrottle = .init(),
        now: @escaping () -> Date = { Date() },
        delay: @escaping @Sendable (TimeInterval) async -> Void = { try? await Task.sleep(for: .seconds($0)) }
    ) {
        self.observeUploads = observeUploads
        self.client = client
        self.throttle = throttle
        self.now = now
        self.delay = delay
    }

    func start() {
        guard subscription == nil else { return }

        WireLogger.wireDrive.info("uploads live activity: following the uploads")
        subscription = observeUploads.invoke().sink { [weak self] summary in
            self?.handle(summary)
        }
    }

    func endActivityIfNoUploads() async {
        let previous = pendingWork
        await previous?.value

        guard latestSummary?.trackedCount ?? 0 == 0 else { return }
        await endAllActivities()
    }

    func stop() async {
        cancelPendingEnd()
        subscription = nil
        latestSummary = nil
        hasSeenUploads = false
        throttle.reset()

        let previous = pendingWork
        await previous?.value

        await endAllActivities()
    }

    // MARK: - Handling summaries

    private func handle(_ summary: WireDriveDirectUploadsSummary) {
        latestSummary = summary
        let date = now()

        // Work is chained, so updates reach the client in the order the summaries arrived.
        let previous = pendingWork
        pendingWork = Task { [weak self] in
            await previous?.value
            await self?.apply(summary, at: date)
        }
    }

    private func apply(_ summary: WireDriveDirectUploadsSummary, at date: Date) async {
        guard summary.trackedCount > 0 else {
            // Everything was cleared or cancelled, so there is nothing left to describe. Before any
            // uploads were seen it only means that they have not been loaded yet.
            if hasSeenUploads {
                await endAllActivities()
            }
            return
        }

        guard client.areActivitiesEnabled else {
            WireLogger.wireDrive.info("uploads live activity: skipped, live activities are disabled for the app")
            return
        }

        hasSeenUploads = true

        let state = WireDriveUploadsActivityState(summary: summary)
        WireLogger.wireDrive.info(
            "uploads live activity: \(state.phase), \(state.uploadedCount) of \(state.totalCount) uploaded, "
                + "\(state.failedCount) failed, activity showing: \(client.hasActivity)"
        )

        if state.isFinished {
            guard client.hasActivity else { return }
            await client.update(with: state)
            endAfterDelay(with: state, dismissal: state.phase == .completed ? .immediately : .systemDefault)
            return
        }

        // More uploads began while the last ones were being shown as done: the activity carries on.
        cancelPendingEnd()

        if client.hasActivity {
            guard throttle.shouldSend(state, at: date) else { return }
            await client.update(with: state)
        } else {
            await startActivity(with: state, at: date)
        }
    }

    private func startActivity(with state: WireDriveUploadsActivityState, at date: Date) async {
        throttle.reset()
        _ = throttle.shouldSend(state, at: date)

        do {
            try await client.start(with: state)
            WireLogger.wireDrive.info("uploads live activity: started")
        } catch {
            WireLogger.wireDrive.error("could not start the uploads live activity: \(error)")
            throttle.reset()
        }
    }

    private func endAfterDelay(
        with state: WireDriveUploadsActivityState,
        dismissal: WireDriveUploadsActivityDismissal
    ) {
        cancelPendingEnd()

        pendingEnd = Task { [weak self, delay] in
            await delay(Constants.completedDismissalDelay)
            guard !Task.isCancelled else { return }
            await self?.endActivity(with: state, dismissal: dismissal)
        }
    }

    private func cancelPendingEnd() {
        pendingEnd?.cancel()
        pendingEnd = nil
    }

    private func endAllActivities() async {
        cancelPendingEnd()
        throttle.reset()
        await client.endAll()
    }

    private func endActivity(
        with state: WireDriveUploadsActivityState?,
        dismissal: WireDriveUploadsActivityDismissal
    ) async {
        throttle.reset()
        guard client.hasActivity else { return }
        await client.end(with: state, dismissal: dismissal)
    }
}
