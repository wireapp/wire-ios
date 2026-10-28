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
import WireDriveUploadsLiveActivity

@testable import WireMessagingAssembly
@testable import WireMessagingDomain

@MainActor
final class WireDriveUploadsLiveActivityControllerTests {
    private let tracker: WireDriveObserveDirectUploadsUseCase
    private let client: FakeUploadsActivityClient
    private let delayGate: UploadsDelayGate
    private let sut: WireDriveUploadsLiveActivityController

    init() {
        let tracker = WireDriveObserveDirectUploadsUseCase()
        let client = FakeUploadsActivityClient()
        let delayGate = UploadsDelayGate()

        self.tracker = tracker
        self.client = client
        self.delayGate = delayGate
        self.sut = WireDriveUploadsLiveActivityController(
            observeUploads: tracker,
            client: client,
            throttle: WireDriveUploadsActivityThrottle(minimumProgressInterval: 1),
            now: { Date(timeIntervalSince1970: 1000) },
            delay: { _ in await delayGate.wait() }
        )
    }

    // MARK: - Starting

    @Test
    func startsAnActivityWhenAnUploadBegins() async {
        sut.start()

        publish([.queued])
        await settle()

        #expect(client.calls == [.start(makeState(total: 1))])
    }

    @Test
    func doesNothingWhenThereAreNoUploads() async {
        sut.start()
        await settle()

        #expect(client.calls.isEmpty)
    }

    @Test
    func doesNothingWhenTheUserDisabledLiveActivities() async {
        client.areActivitiesEnabled = false
        sut.start()

        publish([.queued])
        await settle()

        #expect(client.calls.isEmpty)
    }

    @Test
    func triesAgainOnTheNextChangeWhenStartingFailed() async {
        struct NotAllowed: Error {}
        client.startError = NotAllowed()
        sut.start()

        publish([.queued])
        await settle()
        #expect(client.calls.isEmpty)

        client.startError = nil
        publish([.uploading(progress: 0.5)])
        await settle()

        #expect(client.calls.count == 1)
    }

    // MARK: - Updating

    @Test
    func updatesTheActivityWhenACountChanges() async {
        client.hasActivity = true
        sut.start()

        publishItems([makeUploadItem(.uploaded), makeUploadItem(.uploading(progress: 0.5))])
        await settle()
        publishItems([makeUploadItem(.uploaded), makeUploadItem(.uploaded), makeUploadItem(.queued)])
        await settle()

        #expect(client.calls.count == 2)
    }

    @Test
    func keepsProgressUpdatesWithinTheThrottle() async {
        client.hasActivity = true
        sut.start()

        let items = [makeUploadItem(.uploading(progress: 0.10), size: 1000)]
        publishItems(items)
        await settle()
        // Same text, only the progress moved, and not enough time has passed.
        publishItems([makeUploadItem(.uploading(progress: 0.11), size: 1000)])
        await settle()

        #expect(client.calls.count == 1)
    }

    // MARK: - Ending

    /// An ended activity leaves the Dynamic Island at once, so it is kept up while the result is shown.
    @Test
    func showsTheResultBeforeEndingTheActivityOnceEverythingUploaded() async {
        client.hasActivity = true
        sut.start()

        publishItems([makeUploadItem(.uploaded), makeUploadItem(.uploaded)])
        await settle()

        let final = makeState(.completed, total: 2, uploaded: 2, progress: 1)
        #expect(client.calls == [.update(final)])

        await delayGate.open()
        await settle()

        #expect(client.calls == [.update(final), .end(final, .immediately)])
    }

    @Test
    func keepsTheActivityWhenMoreUploadsBeginWhileTheResultIsShown() async {
        client.hasActivity = true
        sut.start()

        publishItems([makeUploadItem(.uploaded)])
        await settle()
        publishItems([makeUploadItem(.uploaded), makeUploadItem(.queued)])
        await settle()

        await delayGate.open()
        await settle()

        #expect(client.hasActivity)
        #expect(client.calls.allSatisfy { if case .end = $0 { false } else { true } })
    }

    @Test
    func doesNotEndTheActivityAfterStopping() async {
        client.hasActivity = true
        sut.start()

        publishItems([makeUploadItem(.uploaded)])
        await settle()
        await sut.stop()
        await delayGate.open()
        await settle()

        let ends = client.calls.filter {
            switch $0 {
            case .end, .endAll: true
            default: false
            }
        }
        #expect(ends == [.endAll])
    }

    @Test
    func showsTheFailureBeforeEndingTheActivityAndKeepsItOnTheLockScreen() async {
        client.hasActivity = true
        sut.start()

        publishItems([makeUploadItem(.uploaded), makeUploadItem(.failed(error: .unauthorized))])
        await settle()

        let final = makeState(.failed, total: 2, uploaded: 1, failed: 1, progress: 0.5)
        #expect(client.calls == [.update(final)])

        await delayGate.open()
        await settle()

        #expect(client.calls == [.update(final), .end(final, .systemDefault)])
    }

    @Test
    func keepsTheActivityWhenAFailedUploadIsRetriedWhileTheResultIsShown() async {
        client.hasActivity = true
        sut.start()

        publishItems([makeUploadItem(.failed(error: .unauthorized))])
        await settle()
        publishItems([makeUploadItem(.queued)])
        await settle()

        await delayGate.open()
        await settle()

        #expect(client.hasActivity)
        #expect(client.calls.allSatisfy { if case .end = $0 { false } else { true } })
    }

    @Test
    func startsAReplacementWhenAFailedUploadIsRetriedAfterTheActivityEnded() async {
        client.hasActivity = true
        sut.start()
        publish([.failed(error: .unauthorized)])
        await settle()
        await delayGate.open()
        await settle()

        #expect(!client.hasActivity)

        publish([.uploading(progress: 0.5)])
        await settle()

        #expect(client.calls == [
            .update(makeState(.failed, total: 1, failed: 1)),
            .end(makeState(.failed, total: 1, failed: 1), .systemDefault),
            .start(makeState(total: 1, progress: 0.5))
        ])
    }

    @Test
    func endsAtOnceWhenThereIsNothingLeftToShow() async {
        sut.start()
        publish([.queued])
        await settle()

        publishItems([])
        await settle()

        #expect(client.calls.last == .endAll)
    }

    @Test
    func dismissesTheRetainedFailureWhenUploadsAreClearedAfterTheActivityEnded() async {
        client.hasActivity = true
        sut.start()
        publish([.failed(error: .unauthorized), .failed(error: .unauthorized)])
        await settle()
        await delayGate.open()
        await settle()

        #expect(!client.hasActivity)
        let final = makeState(.failed, total: 2, failed: 2)
        #expect(client.calls.last == .end(final, .systemDefault))

        publishItems([])
        await settle()

        #expect(client.calls.last == .endAll)
    }

    @Test
    func dismissesRetainedActivitiesOnceLoadingFindsNoUploadsWithoutACurrentActivity() async {
        sut.start()
        await settle()

        await sut.endActivityIfNoUploads()

        #expect(client.calls == [.endAll])
    }

    @Test
    func cancelsThePendingFailureEndWhenUploadsAreCleared() async {
        client.hasActivity = true
        sut.start()
        publish([.failed(error: .unauthorized)])
        await settle()

        publishItems([])
        await settle()
        await delayGate.open()
        await settle()

        #expect(client.calls == [.update(makeState(.failed, total: 1, failed: 1)), .endAll])
    }

    @Test
    func stillCleansUpEmptyUploadsWhenLiveActivitiesHaveBeenDisabled() async {
        sut.start()
        publish([.queued])
        await settle()
        client.areActivitiesEnabled = false

        publishItems([])
        await settle()

        #expect(client.calls.last == .endAll)
    }

    /// The tracker is empty until the manager has loaded the persisted uploads, and an activity left from
    /// before a relaunch must survive that.
    @Test
    func keepsAnAdoptedActivityWhileTheUploadsAreStillLoading() async {
        client.hasActivity = true
        sut.start()
        await settle()

        #expect(client.calls.isEmpty)
    }

    @Test
    func endsAnAdoptedActivityOnceLoadingShowsThereAreNoUploads() async {
        client.hasActivity = true
        sut.start()
        await settle()

        await sut.endActivityIfNoUploads()

        #expect(client.calls == [.endAll])
    }

    @Test
    func keepsAnAdoptedActivityOnceLoadingFindsUploads() async {
        client.hasActivity = true
        sut.start()

        publish([.uploading(progress: 0.5)])
        await sut.endActivityIfNoUploads()

        #expect(client.calls.allSatisfy { if case .end = $0 { false } else { true } })
    }

    @Test
    func doesNotStartAnActivityForUploadsThatAlreadyFinished() async {
        sut.start()

        publishItems([makeUploadItem(.uploaded)])
        await settle()

        #expect(client.calls.isEmpty)
    }

    @Test
    func stopTakesTheActivityDownAndStopsFollowing() async {
        client.hasActivity = true
        sut.start()

        await sut.stop()
        publish([.queued])
        await settle()

        #expect(client.calls == [.endAll])
    }

    // MARK: - Helpers

    private func publish(_ statuses: [WireDriveDirectUploadItem.Status]) {
        publishItems(statuses.map { makeUploadItem($0) })
    }

    private func publishItems(_ items: [WireDriveDirectUploadItem]) {
        tracker.replaceAll(with: items)
    }

    /// Lets the controller's chained work run.
    private func settle() async {
        for _ in 0 ..< 20 {
            await Task.yield()
        }
    }
}
