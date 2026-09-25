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
@testable import WireMessagingDomainSupport
@testable import WireMessagingUI

@MainActor
final class WireDriveDirectUploadsViewModelTests {

    private let observeFolderUploads = MockWireDriveObserveFolderDirectUploadsUseCaseProtocol()
    private let cancelUpload = MockWireDriveCancelDirectUploadUseCaseProtocol()
    private let cancelUploads = MockWireDriveCancelDirectUploadsUseCaseProtocol()
    private let retryUpload = MockWireDriveRetryDirectUploadUseCaseProtocol()
    private let retryFailedUploads = MockWireDriveRetryFailedDirectUploadsUseCaseProtocol()
    private let clearFinishedUploads = MockWireDriveClearFinishedDirectUploadsUseCaseProtocol()

    private let items = CurrentValueSubject<[WireDriveDirectUploadItem], Never>([])

    /// A second, independent stream keyed to `otherFolderPath`, used to verify that re-scoping the
    /// tracker to a different folder actually stops reacting to the previous one.
    private let otherFolderPath = "cell-1/Folder2"
    private let otherFolderItems = CurrentValueSubject<[WireDriveDirectUploadItem], Never>([])

    init() {
        observeFolderUploads.invokeFolderPath_MockMethod = { [items, otherFolderItems, otherFolderPath] folderPath in
            folderPath == otherFolderPath ? otherFolderItems.eraseToAnyPublisher() : items.eraseToAnyPublisher()
        }
        cancelUpload.invokeUploadID_MockMethod = { _ in }
        cancelUploads.invoke_MockMethod = {}
        retryUpload.invokeUploadID_MockMethod = { _ in }
        retryFailedUploads.invoke_MockMethod = {}
        clearFinishedUploads.invoke_MockMethod = {}
    }

    // MARK: - Presentation

    @Test
    func staysHiddenWhileThereIsNothingToShow() {
        #expect(makeSut().presentation == .hidden)
    }

    @Test
    func surfacesAsAPillWhenABatchStarts() {
        // Given
        let sut = makeSut()

        // When
        send(.preview(fileName: "a.pdf", status: .queued))

        // Then
        #expect(sut.presentation == .pill)
    }

    /// Progress arriving while the user is reading the list must not close it under them.
    @Test
    func doesNotCollapseAnExpandedSheetOnUpdate() {
        // Given
        let sut = makeSut()
        send(.preview(fileName: "a.pdf", status: .queued))
        sut.expand()

        // When
        send(.preview(fileName: "a.pdf", status: .uploading(progress: 0.5)))

        // Then
        #expect(sut.presentation == .sheet)
    }

    @Test
    func hidesItselfOnceEverythingIsCleared() {
        // Given
        let sut = makeSut()
        send(.preview(fileName: "a.pdf", status: .uploaded))

        // When
        items.send([])

        // Then
        #expect(sut.presentation == .hidden)
    }

    @Test
    func collapsesBackToThePill() {
        // Given
        let sut = makeSut()
        send(.preview(fileName: "a.pdf", status: .queued))
        sut.expand()

        // When
        sut.collapse()

        // Then
        #expect(sut.presentation == .pill)
    }

    @Test
    func dismissClearsFinishedUploadsAndHides() async {
        // Given
        let sut = makeSut()
        send(.preview(fileName: "a.pdf", status: .uploaded))

        // When
        await sut.dismiss()

        // Then
        #expect(clearFinishedUploads.invoke_Invocations.count == 1)
        #expect(sut.presentation == .hidden)
    }

    /// Dismissing mid-transfer must leave the pill, or the user loses their way back to progress.
    @Test
    func dismissKeepsThePillWhileTransfersAreStillRunning() async {
        // Given
        let sut = makeSut()
        send(.preview(fileName: "a.pdf", status: .uploading(progress: 0.2)))

        // When
        await sut.dismiss()

        // Then
        #expect(sut.presentation == .pill)
    }

    // MARK: - Upload completion

    /// Lets the file list refresh itself once something new has actually landed.
    @Test
    func firesUploadCompletedOnceAnUploadFinishes() {
        // Given
        let sut = makeSut()
        var completions = 0
        let cancellable = sut.uploadCompleted.sink { completions += 1 }
        send(.preview(fileName: "a.pdf", status: .uploading(progress: 0.5)))

        // When
        send(.preview(fileName: "a.pdf", status: .uploaded))

        // Then
        #expect(completions == 1)

        cancellable.cancel()
    }

    @Test
    func doesNotFireUploadCompletedForProgressAlone() {
        // Given
        let sut = makeSut()
        var completions = 0
        let cancellable = sut.uploadCompleted.sink { completions += 1 }

        // When
        send(.preview(fileName: "a.pdf", status: .uploading(progress: 0.2)))
        send(.preview(fileName: "a.pdf", status: .uploading(progress: 0.6)))

        // Then
        #expect(completions == 0)

        cancellable.cancel()
    }

    /// Re-scoping to a folder that already has finished uploads must not read as something new
    /// having just landed.
    @Test
    func observeDoesNotFireUploadCompletedForAlreadyFinishedUploadsInTheNewFolder() {
        // Given
        let sut = makeSut()
        var completions = 0
        let cancellable = sut.uploadCompleted.sink { completions += 1 }
        otherFolderItems.send([.preview(fileName: "a.pdf", status: .uploaded)])

        // When
        sut.observe(folderPath: otherFolderPath, folderName: "Folder2")

        // Then
        #expect(completions == 0)

        cancellable.cancel()
    }

    // MARK: - Aggregate copy

    @Test
    func titleForOneFileInFlight() {
        let sut = makeSut()
        send(.preview(fileName: "a.pdf", status: .uploading(progress: 0.5)))
        #expect(sut.title == "Uploading 1 file")
    }

    @Test
    func titleForSeveralFilesInFlight() {
        let sut = makeSut()
        send(
            .preview(fileName: "a.pdf", status: .uploading(progress: 0.5)),
            .preview(fileName: "b.pdf", status: .queued),
            .preview(fileName: "c.pdf", status: .queued)
        )
        #expect(sut.title == "Uploading 3 files")
    }

    @Test
    func titleForACompletedSingleUpload() {
        let sut = makeSut()
        send(.preview(fileName: "a.pdf", status: .uploaded))
        #expect(sut.title == "Upload complete")
    }

    @Test
    func titleForACompletedBatch() {
        let sut = makeSut()
        send(
            .preview(fileName: "a.pdf", status: .uploaded),
            .preview(fileName: "b.pdf", status: .uploaded)
        )
        #expect(sut.title == "2 of 2 uploaded")
    }

    @Test
    func titleWhenEverythingFailed() {
        let sut = makeSut()
        send(
            .preview(fileName: "a.pdf", status: .failed(error: .unauthorized)),
            .preview(fileName: "b.pdf", status: .failed(error: .unauthorized))
        )
        #expect(sut.title == "Couldn't upload 2 files")
    }

    @Test
    func titleWhenTheOnlyFileFailed() {
        let sut = makeSut()
        send(.preview(fileName: "a.pdf", status: .failed(error: .unauthorized)))
        #expect(sut.title == "Couldn't upload file")
    }

    /// A partial failure is the actionable case, so the subtitle reports it rather than the
    /// destination.
    /// The headline counts the whole batch, not what is left: the design shows "Uploading 8 files"
    /// next to "2 of 8 uploaded".
    @Test
    func titleCountsTheWholeBatchWhileSomeAreStillRunning() {
        let sut = makeSut()
        send(
            .preview(fileName: "a.pdf", status: .uploaded),
            .preview(fileName: "b.pdf", status: .uploaded),
            .preview(fileName: "c.pdf", status: .uploading(progress: 0.5))
        )
        #expect(sut.title == "Uploading 3 files")
        #expect(sut.subtitle == "2 of 3 uploaded")
    }

    @Test
    func subtitleReportsPartialFailures() {
        let sut = makeSut()
        send(
            .preview(fileName: "a.pdf", status: .uploaded),
            .preview(fileName: "b.pdf", status: .failed(error: .unauthorized))
        )
        #expect(sut.title == "1 of 2 uploaded")
        #expect(sut.subtitle == "1 couldn't upload")
    }

    @Test
    func subtitleFallsBackToTheDestination() {
        let sut = makeSut()
        send(.preview(fileName: "a.pdf", status: .uploading(progress: 0.1)))
        #expect(sut.subtitle == "to Shared Drive")
    }

    @Test
    func subtitleUsesTheNameOfTheFolderBeingObserved() {
        let sut = makeSut()
        sut.observe(folderPath: otherFolderPath, folderName: "Folder2")
        otherFolderItems.send([.preview(fileName: "a.pdf", status: .uploading(progress: 0.1))])
        #expect(sut.subtitle == "to Folder2")
    }

    /// Cancelled uploads are excluded from the "N of M" aggregate.
    @Test
    func aggregateIgnoresCancelledUploads() {
        let sut = makeSut()
        send(
            .preview(fileName: "a.pdf", status: .uploaded),
            .preview(fileName: "b.pdf", status: .cancelled)
        )
        #expect(sut.title == "Upload complete")
    }

    // MARK: - Header action

    @Test
    func offersCancelAllWhileTransfersAreRunning() {
        let sut = makeSut()
        send(.preview(fileName: "a.pdf", status: .uploading(progress: 0.1)))
        #expect(sut.headerAction == .cancelAll)
    }

    @Test
    func offersRetryAllWhenFailuresCanBeRetried() {
        let sut = makeSut()
        send(.preview(fileName: "a.pdf", status: .failed(error: .unauthorized), isRetryable: true))
        #expect(sut.headerAction == .retryAll)
    }

    /// A permanent failure has nothing to offer, so the header shows no action.
    @Test
    func offersNothingWhenFailuresCannotBeRetried() {
        let sut = makeSut()
        send(.preview(fileName: "a.pdf", status: .failed(error: .fileNotFound), isRetryable: false))
        #expect(sut.headerAction == nil)
    }

    @Test
    func offersNothingOnceEverythingSucceeded() {
        let sut = makeSut()
        send(.preview(fileName: "a.pdf", status: .uploaded))
        #expect(sut.headerAction == nil)
    }

    // MARK: - Actions

    @Test
    func cancelAllForwardsToTheMechanism() async {
        let sut = makeSut()
        await sut.perform(.cancelAll)
        #expect(cancelUploads.invoke_Invocations.count == 1)
    }

    @Test
    func retryAllForwardsToTheMechanism() async {
        let sut = makeSut()
        await sut.perform(.retryAll)
        #expect(retryFailedUploads.invoke_Invocations.count == 1)
    }

    @Test
    func cancelForwardsTheUploadIdentifier() async {
        let sut = makeSut()
        let uploadID = UUID()
        await sut.cancel(uploadID: uploadID)
        #expect(cancelUpload.invokeUploadID_Invocations == [uploadID])
    }

    @Test
    func retryForwardsTheUploadIdentifier() async {
        let sut = makeSut()
        let uploadID = UUID()
        await sut.retry(uploadID: uploadID)
        #expect(retryUpload.invokeUploadID_Invocations == [uploadID])
    }

    // MARK: - Helpers

    private func makeSut(rootFolderPath: String = "cell-1") -> WireDriveDirectUploadsViewModel {
        WireDriveDirectUploadsViewModel(
            rootFolderPath: rootFolderPath,
            observeFolderUploads: observeFolderUploads,
            cancelUpload: cancelUpload,
            cancelUploads: cancelUploads,
            retryUpload: retryUpload,
            retryFailedUploads: retryFailedUploads,
            clearFinishedUploads: clearFinishedUploads
        )
    }

    private func send(_ items: WireDriveDirectUploadItem...) {
        self.items.send(items)
    }

    // MARK: - Conversation scoping

    /// The mechanism is shared across every open conversation, so the view model must observe only
    /// its own conversation's folder, not every upload in flight.
    @Test
    func observesOnlyItsOwnRootFolder() {
        _ = makeSut(rootFolderPath: "cell-1/Documents")
        #expect(observeFolderUploads.invokeFolderPath_Invocations == ["cell-1/Documents"])
    }

    /// The sheet is scoped to wherever the user currently is, not to wherever it first appeared —
    /// navigating must re-subscribe rather than keep watching the original folder forever.
    @Test
    func observeReSubscribesToTheNewFolder() {
        let sut = makeSut(rootFolderPath: "cell-1")

        sut.observe(folderPath: otherFolderPath, folderName: "Folder2")

        #expect(observeFolderUploads.invokeFolderPath_Invocations == ["cell-1", otherFolderPath])
    }

    /// Once re-scoped, updates to the folder left behind must not leak into the tracker.
    @Test
    func observeStopsReactingToThePreviousFolder() {
        let sut = makeSut(rootFolderPath: "cell-1")
        sut.observe(folderPath: otherFolderPath, folderName: "Folder2")

        // When — a change lands in "cell-1", which is no longer being observed.
        items.send([.preview(fileName: "a.pdf", status: .uploading(progress: 0.1))])

        // Then
        #expect(sut.summary.items.isEmpty)
    }
}
