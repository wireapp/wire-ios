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

@testable import WireMessagingDomain

/// Covers `WireDriveDirectUploadTrackerProtocol`'s mechanics directly, with no pipeline wired up at all:
/// `WireDriveDirectUploadManager` only ever calls `replaceAll`/`upsert`/`updateProgress`/`removeAll`,
/// so those are the seam to drive from a test. `WireDriveDirectUploadManagerTests` separately covers
/// that the manager actually calls them at the right times.
@MainActor
struct WireDriveObserveDirectUploadsUseCaseTests {

    private let sut = WireDriveObserveDirectUploadsUseCase()

    // MARK: - Summary

    @Test
    func summaryReflectsWhatWasPublished() {
        // Given
        let a = makeItem(fileName: "a.pdf")
        let b = makeItem(fileName: "b.pdf")

        // When
        sut.upsert([a, b])

        // Then
        #expect(sut.summary.items.count == 2)
    }

    /// The tracker sheet is global to the drive session and outlives folder navigation, so a view
    /// that subscribes after an upload has already started must still see it.
    @Test
    func summaryPublisherReplaysCurrentStateToALateSubscriber() {
        // Given
        sut.upsert([makeItem()])

        // When
        var received: WireDriveDirectUploadsSummary?
        let subscription = sut.summaryPublisher.sink { received = $0 }
        defer { subscription.cancel() }

        // Then
        #expect(received?.items.count == 1)
    }

    /// A stream that emitted on every identical republish would be pointless; `removeDuplicates` is
    /// what makes the tracker cheap to observe.
    @Test
    func summaryPublisherDoesNotEmitWhenNothingChanged() {
        // Given
        let item = makeItem()
        sut.upsert([item])

        var emissions = 0
        let subscription = sut.summaryPublisher.sink { _ in emissions += 1 }
        defer { subscription.cancel() }

        // When — republishing the identical item is a no-op on the tracked state.
        sut.upsert([item])

        // Then — only the replayed value.
        #expect(emissions == 1)
    }

    // MARK: - Upsert vs. replace

    @Test
    func upsertMergesWithoutDroppingWhatIsAbsent() {
        // Given
        let a = makeItem(fileName: "a.pdf")
        let b = makeItem(fileName: "b.pdf")
        sut.upsert([a, b])

        // When — republishing only `a` must not drop `b`.
        sut.upsert([a.with(status: .uploaded)])

        // Then
        #expect(sut.summary.items.map(\.fileName).sorted() == ["a.pdf", "b.pdf"])
    }

    @Test
    func replaceAllDropsWhatIsAbsent() {
        // Given
        let a = makeItem(fileName: "a.pdf")
        let b = makeItem(fileName: "b.pdf")
        sut.upsert([a, b])

        // When
        sut.replaceAll(with: [a])

        // Then
        #expect(sut.summary.items.map(\.fileName) == ["a.pdf"])
    }

    // MARK: - Per-upload publisher

    @Test
    func perUploadPublisherEmitsNilOnceTheUploadIsForgotten() {
        // Given
        let item = makeItem()
        sut.upsert([item])

        var received: [WireDriveDirectUploadItem?] = []
        let subscription = sut.publisher(uploadID: item.id).sink { received.append($0) }
        defer { subscription.cancel() }

        // When
        sut.replaceAll(with: [])

        // Then
        #expect(received.last ?? .some(nil) == nil)
    }

    // MARK: - Folder publisher

    @Test
    func folderPublisherFiltersByDestination() {
        // Given
        let a = makeItem(fileName: "a.pdf", destinationFolderPath: "cell-1/Documents")
        let b = makeItem(fileName: "b.pdf", destinationFolderPath: "cell-1/Photos")
        sut.upsert([a, b])

        // When
        var received: [WireDriveDirectUploadItem]?
        let subscription = sut.publisher(folderPath: "cell-1/Documents").sink { received = $0 }
        defer { subscription.cancel() }

        // Then
        #expect(received?.map(\.fileName) == ["a.pdf"])
    }

    /// The sheet re-subscribes to wherever the user is currently browsing, so a subfolder's uploads
    /// must not also show while looking at its parent — the mechanism is a single instance shared
    /// across every open conversation, so exact matching is also what keeps a sibling conversation
    /// whose cell name happens to share a prefix from leaking in.
    @Test
    func folderPublisherExcludesSubfoldersAndUnrelatedConversations() {
        // Given
        let a = makeItem(fileName: "a.pdf", destinationFolderPath: "cell-1")
        let b = makeItem(fileName: "b.pdf", destinationFolderPath: "cell-1/Documents")
        let c = makeItem(fileName: "c.pdf", destinationFolderPath: "cell-10")
        sut.upsert([a, b, c])

        // When
        var received: [WireDriveDirectUploadItem]?
        let subscription = sut.publisher(folderPath: "cell-1").sink { received = $0 }
        defer { subscription.cancel() }

        // Then
        #expect(received?.map(\.fileName) == ["a.pdf"])
    }

    @Test
    func folderPublisherOrdersOldestFirst() {
        // Given
        let older = makeItem(fileName: "older.pdf", createdAt: Date(timeIntervalSince1970: 0))
        let newer = makeItem(fileName: "newer.pdf", createdAt: Date(timeIntervalSince1970: 1))
        sut.upsert([newer, older])

        // When
        var received: [WireDriveDirectUploadItem]?
        let subscription = sut.publisher(folderPath: "cell-1/Documents").sink { received = $0 }
        defer { subscription.cancel() }

        // Then
        #expect(received?.map(\.fileName) == ["older.pdf", "newer.pdf"])
    }

    // MARK: - Progress

    @Test
    func updateProgressAppliesToAQueuedUpload() {
        // Given
        let item = makeItem(status: .queued)
        sut.upsert([item])

        // When
        sut.updateProgress(uploadID: item.id, progress: 0.4)

        // Then
        #expect(sut.summary.items.first?.status == .uploading(progress: 0.4))
    }

    @Test
    func updateProgressClampsToUnitRange() {
        // Given
        let item = makeItem(status: .uploading(progress: 0.1))
        sut.upsert([item])

        // When
        sut.updateProgress(uploadID: item.id, progress: 4)

        // Then
        #expect(sut.summary.items.first?.status == .uploading(progress: 1))
    }

    /// A late progress sample must not resurrect an upload the user has already cancelled, or one
    /// that has finished.
    @Test
    func updateProgressIgnoresATerminalUpload() {
        // Given
        let item = makeItem(status: .uploaded)
        sut.upsert([item])

        // When
        sut.updateProgress(uploadID: item.id, progress: 0.5)

        // Then
        #expect(sut.summary.items.first?.status == .uploaded)
    }

    @Test
    func updateProgressIgnoresAnUntrackedUpload() {
        // When / Then — must not trap.
        sut.updateProgress(uploadID: UUID(), progress: 0.5)
        #expect(sut.summary.items.isEmpty)
    }

    // MARK: - Removing

    @Test
    func removeAllEmptiesTheTrackedSet() {
        // Given
        sut.upsert([makeItem(), makeItem()])

        // When
        sut.removeAll()

        // Then
        #expect(sut.summary.items.isEmpty)
    }

    // MARK: - Helpers

    private func makeItem(
        fileName: String = "report.pdf",
        destinationFolderPath: String = "cell-1/Documents",
        status: WireDriveDirectUploadItem.Status = .queued,
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> WireDriveDirectUploadItem {
        WireDriveDirectUploadItem(
            id: UUID(),
            batchID: UUID(),
            nodeID: UUID(),
            fileName: fileName,
            fileSize: 2048,
            destinationFolderPath: destinationFolderPath,
            status: status,
            createdAt: createdAt,
            isRetryable: false
        )
    }
}

private extension WireDriveDirectUploadItem {

    func with(status: WireDriveDirectUploadItem.Status) -> WireDriveDirectUploadItem {
        WireDriveDirectUploadItem(
            id: id,
            batchID: batchID,
            nodeID: nodeID,
            fileName: fileName,
            fileSize: fileSize,
            destinationFolderPath: destinationFolderPath,
            status: status,
            createdAt: createdAt,
            isRetryable: isRetryable
        )
    }
}
