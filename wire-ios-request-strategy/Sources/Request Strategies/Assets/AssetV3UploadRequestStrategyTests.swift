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

import WireUtilities
import XCTest
@testable import WireRequestStrategy

class AssetV3UploadRequestStrategyTests: MessagingTestBase {

    var sut: AssetV3UploadRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()

        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        sut = AssetV3UploadRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus,
            localDomain: "wire.com",
            isCloudDomain: false
        )
    }

    override func tearDown() {

        sut = nil
        mockApplicationStatus = nil

        super.tearDown()
    }

    // MARK: - Helpers

    @discardableResult
    func createFileMessage(
        transferState: AssetTransferState = .uploading,
        hasCompletedPreprocessing: Bool = true,
        line: UInt = #line
    ) -> ZMAssetClientMessage {
        let targetConversation = groupConversation!
        let url = Bundle(for: AssetClientMessageRequestStrategyTests.self).url(
            forResource: "Lorem Ipsum",
            withExtension: "txt"
        )!
        let message = try! targetConversation.appendFile(with: ZMFileMetadata(
            fileURL: url,
            thumbnail: verySmallJPEGData()
        )) as! ZMAssetClientMessage
        message.updateTransferState(transferState, synchronize: true)

        if hasCompletedPreprocessing {
            for asset in message.assets {
                if asset.needsPreprocessing {
                    asset.updateWithPreprocessedData(
                        verySmallJPEGData(),
                        imageProperties: ZMIImageProperties(
                            size: CGSize(width: 100, height: 100),
                            length: 100,
                            mimeType: "image/jpeg"
                        )
                    )
                }
                asset.encrypt()
            }
        }

        syncMOC.saveOrRollback()

        return message
    }

    @discardableResult
    func createImageMessage(
        transferState: AssetTransferState = .uploading,
        line: UInt = #line
    ) -> ZMAssetClientMessage {
        let targetConversation = groupConversation!
        let message = try! targetConversation.appendImage(
            SendableImage(name: "picture.jpg", utType: .jpeg, data: verySmallJPEGData()),
            nonce: UUID()
        ) as! ZMAssetClientMessage
        message.updateTransferState(transferState, synchronize: true)

        for asset in message.assets {
            if asset.needsPreprocessing {
                asset.updateWithPreprocessedData(
                    verySmallJPEGData(),
                    imageProperties: ZMIImageProperties(
                        size: CGSize(width: 100, height: 100),
                        length: 100,
                        mimeType: "image/jpeg"
                    )
                )
            }
            asset.encrypt()
        }

        syncMOC.saveOrRollback()

        return message
    }

    // MARK: - Request generation

    func testThatItGeneratesRequestWhenAssetIsPreprocessed() {
        syncMOC.performGroupedAndWait {
            // given
            let message = self.createFileMessage()
            let messageSet: Set<NSManagedObject> = [message]
            self.sut.upstreamSync?.objectsDidChange(messageSet)

            // when
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNotNil(request)
        }
    }

    func testThatItDoesNotGenerateRequestForVersion2Assets() {
        syncMOC.performGroupedAndWait {
            // given
            let message = self.createFileMessage()
            message.version = 2
            let messageSet: Set<NSManagedObject> = [message]
            self.sut.upstreamSync?.objectsDidChange(messageSet)

            // when
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNil(request)
        }
    }

    func testThatItDoesNotGenerateRequestForDeliveredMessages() {
        syncMOC.performGroupedAndWait {
            // given
            let message = self.createFileMessage()
            message.delivered = true
            let messageSet: Set<NSManagedObject> = [message]
            self.sut.upstreamSync?.objectsDidChange(messageSet)

            // when
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNil(request)
        }
    }

    func testThatItDoesNotGenerateRequestWhilePreprocessingIsNotCompleted() {
        syncMOC.performGroupedAndWait {
            // given
            let message = self.createFileMessage(hasCompletedPreprocessing: false)
            let messageSet: Set<NSManagedObject> = [message]
            self.sut.upstreamSync?.objectsDidChange(messageSet)

            // when
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNil(request)
        }
    }

    func testThatItDoesNotGenerateRequestWhenTransferStateIsNotUploading() {
        let allTransferStatesExpectUploading: [AssetTransferState] = [.uploaded, .uploadingFailed, .uploadingCancelled]

        allTransferStatesExpectUploading.forEach { transferState in
            syncMOC.performGroupedAndWait {
                // given
                let message = self.createFileMessage(transferState: transferState)
                let messageSet: Set<NSManagedObject> = [message]
                self.sut.upstreamSync?.objectsDidChange(messageSet)

                // when
                let request = self.sut.nextRequest(for: .v0)

                // then
                XCTAssertNil(request)
            }
        }
    }

    // MARK: - Request cancellation

    func testThatItCancelsRequest_WhenTransferStateChangesToUploadingCancelled() {
        let expectedIdentifier: UInt = 42
        var message: ZMAssetClientMessage!
        syncMOC.performGroupedAndWait {
            // given
            message = self.createFileMessage()
            let messageSet: Set<NSManagedObject> = [message]
            self.sut.upstreamSync?.objectsDidChange(messageSet)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("Request is nil") }
            request.callTaskCreationHandlers(withIdentifier: expectedIdentifier, sessionIdentifier: self.name)
        }

        syncMOC.performGroupedBlock {
            // when
            message.fileMessageData?.cancelTransfer()
            let messageSet: Set<NSManagedObject> = [message]
            self.sut.objectsDidChange(messageSet) // this would be called after a save
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // then - the cancellation provider should be informed to cancel the request
            let cancelledIdentifier = self.mockApplicationStatus.cancelledIdentifiers.first
            XCTAssertEqual(self.mockApplicationStatus.cancelledIdentifiers.count, 1)
            XCTAssertEqual(cancelledIdentifier?.identifier, expectedIdentifier)
            XCTAssertNil(message.associatedTaskIdentifier, "Should nil-out the identifier after it has been cancelled")
        }
    }

    // MARK: - Response handling

    func testThatItUpdatesUploadProgress() {
        let expectedProgress: Float = 0.5
        var message: ZMAssetClientMessage!
        syncMOC.performGroupedAndWait {
            // given
            message = self.createFileMessage()
            let messageSet: Set<NSManagedObject> = [message]
            self.sut.upstreamSync?.objectsDidChange(messageSet)
            let request = self.sut.nextRequest(for: .v0)

            // when
            request?.updateProgress(expectedProgress)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertEqual(message.progress, expectedProgress)
        }
    }

    func testThatItUpdatesTransferState_OnSuccessfulResponse() {
        var message: ZMAssetClientMessage!
        syncMOC.performGroupedAndWait {
            // given
            message = self.createImageMessage()
            let messageSet: Set<NSManagedObject> = [message]
            self.sut.upstreamSync?.objectsDidChange(messageSet)
            let request = self.sut.nextRequest(for: .v0)

            // when
            request?.complete(with: ZMTransportResponse(
                payload: ["key": "asset-id-123"] as ZMTransportData,
                httpStatus: 201,
                transportSessionError: nil,
                apiVersion: 0
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            XCTAssertEqual(message.transferState, .uploaded)
        }
    }

    func testThatItDoesNotUpdateTransferState_OnSuccessfulResponse_WhenThereIsMoreAssetsToUpload() {
        var message: ZMAssetClientMessage!
        syncMOC.performGroupedAndWait {
            // given
            message = self.createFileMessage() // has two assets (file and thumbnail)
            let messageSet: Set<NSManagedObject> = [message]
            self.sut.upstreamSync?.objectsDidChange(messageSet)
            let request = self.sut.nextRequest(for: .v0)

            // when
            request?.complete(with: ZMTransportResponse(
                payload: ["key": "asset-id-123"] as ZMTransportData,
                httpStatus: 201,
                transportSessionError: nil,
                apiVersion: 0
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            XCTAssertEqual(message.transferState, .uploading)
        }
    }

    func testThatItAddsAssetId_OnSuccessfulResponse() {
        let expectedAssetId = "asset-id-123"
        var message: ZMAssetClientMessage!
        syncMOC.performGroupedAndWait {
            // given
            message = self.createImageMessage()
            let messageAsset: Set<NSManagedObject> = [message]
            self.sut.upstreamSync?.objectsDidChange(messageAsset)
            let request = self.sut.nextRequest(for: .v0)

            // when
            request?.complete(with: ZMTransportResponse(
                payload: ["key": expectedAssetId] as ZMTransportData,
                httpStatus: 201,
                transportSessionError: nil,
                apiVersion: 0
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            XCTAssertEqual(message?.underlyingMessage?.assetData?.uploaded.assetID, expectedAssetId)
        }
    }

    func testThatItExpiresTheMessage_OnPermanentFailureResponse() {
        var message: ZMAssetClientMessage!
        syncMOC.performGroupedAndWait {
            // given
            message = self.createImageMessage()
            let messageSet: Set<NSManagedObject> = [message]
            self.sut.upstreamSync?.objectsDidChange(messageSet)
            let request = self.sut.nextRequest(for: .v0)

            // when
            request?.complete(with: ZMTransportResponse(
                payload: nil,
                httpStatus: 404,
                transportSessionError: nil,
                apiVersion: 0
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            XCTAssertTrue(message.isExpired)
            XCTAssertEqual(message.transferState, .uploadingFailed)
        }
    }

}

// MARK: - Offline pending messages

extension AssetV3UploadRequestStrategyTests {

    func testThatItFailsUploadThatWaitedLongerThanMaxPendingDuration_OfflinePendingMessages() {
        // GIVEN
        DeveloperFlag.storage = .temporary()
        DeveloperFlag.offlinePendingMessages.enable(true)
        defer { DeveloperFlag.storage = .standard }

        syncMOC.performGroupedAndWait {
            let message = self.createFileMessage()
            message.serverTimestamp = Date(timeIntervalSinceNow: -ZMAssetClientMessage.maxPendingDuration - 1)

            // WHEN
            self.sut.pendingUploadDeadlineTimer.addTrackedObjects([message])

            // THEN
            XCTAssertTrue(message.isExpired)
            XCTAssertEqual(message.expirationReason, .timeout)
            XCTAssertEqual(message.transferState, .uploadingFailed)
        }
    }

    func testThatItFailsUploadWhenMaxPendingDurationPassesWhileWaiting_OfflinePendingMessages() {
        // GIVEN
        DeveloperFlag.storage = .temporary()
        DeveloperFlag.offlinePendingMessages.enable(true)
        defer { DeveloperFlag.storage = .standard }

        var message: ZMAssetClientMessage!
        syncMOC.performGroupedAndWait {
            message = self.createFileMessage()
            message.serverTimestamp = Date(timeIntervalSinceNow: -ZMAssetClientMessage.maxPendingDuration + 0.5)
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.pendingUploadDeadlineTimer.objectsDidChange([message])
            XCTAssertFalse(message.isExpired)
        }
        let deadlinePassed = XCTestExpectation(description: "deadline passed")
        deadlinePassed.isInverted = true
        wait(for: [deadlinePassed], timeout: 1.5)

        // THEN
        syncMOC.performGroupedAndWait {
            XCTAssertTrue(message.isExpired)
            XCTAssertEqual(message.transferState, .uploadingFailed)
        }
    }

    func testThatItDoesNotFailEphemeralUploadAfterMaxPendingDuration_OfflinePendingMessages() {
        // GIVEN
        DeveloperFlag.storage = .temporary()
        DeveloperFlag.offlinePendingMessages.enable(true)
        defer { DeveloperFlag.storage = .standard }

        syncMOC.performGroupedAndWait {
            self.groupConversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
            let message = self.createFileMessage()
            XCTAssertTrue(message.isEphemeral)
            message.serverTimestamp = Date(timeIntervalSinceNow: -ZMAssetClientMessage.maxPendingDuration - 1)

            // WHEN
            self.sut.pendingUploadDeadlineTimer.addTrackedObjects([message])

            // THEN
            XCTAssertFalse(message.isExpired)
            XCTAssertEqual(message.transferState, .uploading)
        }
    }

    func testThatItDoesNotFailUploadAfterMaxPendingDuration_WhenFlagIsDisabled() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let message = self.createFileMessage()
            message.serverTimestamp = Date(timeIntervalSinceNow: -ZMAssetClientMessage.maxPendingDuration - 1)

            // WHEN
            self.sut.pendingUploadDeadlineTimer.addTrackedObjects([message])

            // THEN
            XCTAssertFalse(message.isExpired)
            XCTAssertEqual(message.transferState, .uploading)
        }
    }
}
