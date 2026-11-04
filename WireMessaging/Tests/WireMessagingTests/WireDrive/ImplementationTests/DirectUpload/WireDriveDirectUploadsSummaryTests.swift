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

@testable import WireMessagingDomain

/// Covers `WireDriveDirectUploadsSummary`'s counting and weighting logic directly, with no mechanism
/// wired up at all: it is a pure value type, so there is no reason to go through
/// `WireDriveDirectUploadManager` to exercise it.
struct WireDriveDirectUploadsSummaryTests {

    @Test
    func countsEachStatus() {
        // Given
        let summary = WireDriveDirectUploadsSummary(items: [
            makeItem(status: .queued),
            makeItem(status: .uploading(progress: 0.5)),
            makeItem(status: .uploaded),
            makeItem(status: .uploaded),
            makeItem(status: .failed(error: .unauthorized)),
            makeItem(status: .cancelled)
        ])

        // Then
        #expect(summary.queuedCount == 1)
        #expect(summary.uploadingCount == 1)
        #expect(summary.uploadedCount == 2)
        #expect(summary.failedCount == 1)
        #expect(summary.cancelledCount == 1)
        #expect(summary.activeCount == 2)
        // Cancelled uploads are excluded: the user removed them, so they must not inflate "N of M".
        #expect(summary.trackedCount == 5)
        #expect(!summary.isFinished)
    }

    @Test
    func overallProgressIsWeightedByFileSize() {
        // Given — a large file at 50% and a tiny finished one.
        let summary = WireDriveDirectUploadsSummary(items: [
            makeItem(fileSize: 1000, status: .uploading(progress: 0.5)),
            makeItem(fileSize: 100, status: .uploaded)
        ])

        // Then — 500 + 100 sent out of 1100.
        #expect(abs(summary.overallProgress - (600.0 / 1100.0)) < 0.001)
    }

    /// Cancelling a large file must not make the remaining uploads appear to jump backwards.
    @Test
    func overallProgressExcludesCancelledUploads() {
        // Given
        let summary = WireDriveDirectUploadsSummary(items: [
            makeItem(fileSize: 100, status: .uploaded),
            makeItem(fileSize: 10_000, status: .cancelled)
        ])

        // Then
        #expect(summary.overallProgress == 1)
    }

    @Test
    func isFinishedWhenNothingIsLeftToUpload() {
        // Given
        let summary = WireDriveDirectUploadsSummary(items: [
            makeItem(status: .uploaded),
            makeItem(status: .failed(error: .unauthorized))
        ])

        // Then
        #expect(summary.isFinished)
        #expect(summary.hasFailures)
    }

    @Test
    func emptySummaryHasNoProgress() {
        let summary = WireDriveDirectUploadsSummary(items: [])
        #expect(summary.overallProgress == 0)
        #expect(summary.isFinished)
        #expect(!summary.hasFailures)
    }

    @Test
    func staticEmptyMatchesAnEmptyInit() {
        #expect(WireDriveDirectUploadsSummary.empty == WireDriveDirectUploadsSummary(items: []))
    }

    @Test
    func sortsItemsOldestFirstRegardlessOfInputOrder() {
        // Given
        let older = makeItem(createdAt: Date(timeIntervalSince1970: 100))
        let newer = makeItem(createdAt: Date(timeIntervalSince1970: 200))

        // When
        let summary = WireDriveDirectUploadsSummary(items: [newer, older])

        // Then
        #expect(summary.items.map(\.id) == [older.id, newer.id])
    }

    /// Only a retryable failure should offer a retry action; a permanent one has nothing to offer.
    @Test
    func hasRetryableFailuresReflectsWhetherAnyFailureCanBeRetried() {
        let retryable = WireDriveDirectUploadsSummary(items: [
            makeItem(status: .failed(error: .unauthorized), isRetryable: true)
        ])
        #expect(retryable.hasRetryableFailures)

        let permanent = WireDriveDirectUploadsSummary(items: [
            makeItem(status: .failed(error: .fileNotFound), isRetryable: false)
        ])
        #expect(!permanent.hasRetryableFailures)
    }

    // MARK: - Helpers

    private func makeItem(
        fileSize: UInt64 = 2048,
        status: WireDriveDirectUploadItem.Status = .queued,
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000),
        isRetryable: Bool = false
    ) -> WireDriveDirectUploadItem {
        WireDriveDirectUploadItem(
            id: UUID(),
            batchID: UUID(),
            nodeID: UUID(),
            fileName: "report.pdf",
            fileSize: fileSize,
            destinationFolderPath: "cell-1/Documents",
            status: status,
            createdAt: createdAt,
            isRetryable: isRetryable
        )
    }
}
