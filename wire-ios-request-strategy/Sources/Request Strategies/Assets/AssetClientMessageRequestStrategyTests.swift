//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireDataModel
import WireRequestStrategy
import WireRequestStrategySupport
import XCTest

final class AssetClientMessageRequestStrategyTests: MessagingTestBase {
    // MARK: Internal

    override func setUp() {
        super.setUp()

        mockMessageSender = MockMessageSenderInterface()

        sut = syncMOC.performAndWait {
            AssetClientMessageRequestStrategy(
                managedObjectContext: self.syncMOC,
                messageSender: mockMessageSender
            )
        }
    }

    override func tearDown() {
        mockMessageSender = nil
        sut = nil
        super.tearDown()
    }

    // MARK: Helper

    @discardableResult
    func createMessage(
        isImage: Bool = true,
        uploaded: Bool = false,
        preview: Bool = false,
        assetId: Bool = false,
        expired: Bool = false,
        previewAssetId: Bool = false,
        transferState: AssetTransferState = .uploading,
        conversation: ZMConversation? = nil,
        sender: ZMUser? = nil,
        line: UInt = #line
    ) -> ZMAssetClientMessage {
        let targetConversation = conversation ?? groupConversation!
        let message: ZMAssetClientMessage!
        if isImage {
            message = try! targetConversation.appendImage(from: imageData) as? ZMAssetClientMessage
        } else {
            let url = Bundle(for: AssetClientMessageRequestStrategyTests.self).url(
                forResource: "Lorem Ipsum",
                withExtension: "txt"
            )!
            message = try! targetConversation.appendFile(with: ZMFileMetadata(
                fileURL: url,
                thumbnail: nil
            )) as? ZMAssetClientMessage
        }

        if isImage {
            let size = CGSize(width: 368, height: 520)
            let properties = ZMIImageProperties(size: size, length: 1024, mimeType: "image/jpg")!
            message.assets.first?.updateWithPreprocessedData(imageData, imageProperties: properties)
            XCTAssertEqual(message.mimeType, "image/jpg", line: line)
            XCTAssertEqual(message.size, 1024, line: line)
            XCTAssertEqual(message.imageMessageData?.originalSize, size, line: line)
            XCTAssertTrue(message.underlyingMessage!.assetData!.hasOriginal, line: line)
        }

        if preview {
            let (otr, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
            let previewId: String? = previewAssetId ? UUID.create().transportString() : nil
            let remote = WireProtos.Asset.RemoteData(withOTRKey: otr, sha256: sha, assetId: previewId, assetToken: nil)
            let imageMetadata = WireProtos.Asset.ImageMetaData(width: 123, height: 420)
            let previewAsset = WireProtos.Asset.Preview(
                size: 128,
                mimeType: "image/jpg",
                remoteData: remote,
                imageMetadata: imageMetadata
            )

            let previewMessage = GenericMessage(
                content: WireProtos.Asset(original: nil, preview: previewAsset),
                nonce: message.nonce!,
                expiresAfter: targetConversation.activeMessageDestructionTimeoutValue
            )

            XCTAssertNoThrow(try message.setUnderlyingMessage(previewMessage))

            XCTAssertTrue(message.underlyingMessage!.assetData!.hasPreview, line: line)
            XCTAssertEqual(message.underlyingMessage!.assetData!.preview.remote.hasAssetID, previewAssetId, line: line)
            XCTAssertEqual(
                message.isEphemeral,
                targetConversation.activeMessageDestructionTimeoutValue != nil,
                line: line
            )
        }

        if uploaded {
            let (otr, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
            var uploaded = GenericMessage(
                content: WireProtos.Asset(withUploadedOTRKey: otr, sha256: sha),
                nonce: message.nonce!,
                expiresAfter: targetConversation.activeMessageDestructionTimeoutValue
            )
            if assetId {
                uploaded.updateUploaded(assetId: UUID.create().transportString(), token: nil, domain: nil)
            }

            XCTAssertNoThrow(try message.setUnderlyingMessage(uploaded))

            message.updateTransferState(.uploaded, synchronize: true)
            XCTAssertTrue(message.underlyingMessage!.assetData!.hasUploaded, line: line)
            XCTAssertEqual(
                message.isEphemeral,
                groupConversation.activeMessageDestructionTimeoutValue != nil,
                line: line
            )
        } else {
            message.updateTransferState(transferState, synchronize: true) // TODO: jacob
        }

        if let sender {
            message.sender = sender
        }

        if expired {
            message.expire()
        }

        syncMOC.saveOrRollback()
        prepareUpload(of: message)

        XCTAssertEqual(message.version, 3, line: line)
        guard case .image? = message.underlyingMessage?.assetData?.original.metaData else {
            XCTAssertEqual(false, isImage, line: line)
            return message
        }
        XCTAssertEqual(true, isImage, line: line)

        return message
    }

    func prepareUpload(of message: ZMAssetClientMessage) {
        ZMChangeTrackerBootstrap.bootStrapChangeTrackers(sut.contextChangeTrackers, on: syncMOC)
    }

    func testThatItDoesNotScheduleAMessageForAnImageMessageUploadedByOtherUser() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            _ = self.createMessage(uploaded: true, sender: self.otherUser)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(0, mockMessageSender.sendMessageMessage_Invocations.count)
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWhichIsExpired() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            _ = self.createMessage(uploaded: true, expired: true)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(0, mockMessageSender.sendMessageMessage_Invocations.count)
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithoutUploaded() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            self.createMessage(uploaded: false)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(0, mockMessageSender.sendMessageMessage_Invocations.count)
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithUploadedAndAssetIdInTheWrongTransferState() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            let message = self.createMessage()
            message.updateTransferState(.uploaded, synchronize: true)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(0, mockMessageSender.sendMessageMessage_Invocations.count)
    }

    func testThatItCreatesARequestForAnUploadedImageMessage() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            self.createMessage(uploaded: true, assetId: true)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(1, mockMessageSender.sendMessageMessage_Invocations.count)
    }

    func testThatItCreatesARequestForAnUploadedImageMessage_Ephemeral() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            self.groupConversation.setMessageDestructionTimeoutValue(.custom(15), for: .selfUser)
            self.createMessage(uploaded: true, assetId: true)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(1, mockMessageSender.sendMessageMessage_Invocations.count)
    }

    func testThatItExpiresAMessageWhenItReceivesAFailureResponse() {
        // GIVEN
        mockMessageSender.sendMessageMessage_MockError = MessageSendError.messageExpired
        var message: ZMAssetClientMessage!
        syncMOC.performGroupedAndWait {
            message = self.createMessage(uploaded: true, assetId: true)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedAndWait {
            XCTAssert(message.isExpired)
            XCTAssertEqual(message.deliveryState, .failedToSend)
        }
    }

    func testThatItNotifiesWhenAnImageCannotBeSent_MissingLegalholdConsent() {
        // GIVEN
        let response = ZMTransportResponse(payload: nil, httpStatus: 403, transportSessionError: nil, apiVersion: 0)
        let missingLegalholdConsentFailure = Payload.ResponseFailure(
            code: 403,
            label: .missingLegalholdConsent,
            message: "",
            data: nil
        )
        let failure = NetworkError.invalidRequestError(missingLegalholdConsentFailure, response)
        mockMessageSender.sendMessageMessage_MockError = failure
        var token: Any?
        syncMOC.performGroupedAndWait {
            self.createMessage(uploaded: true, assetId: true)
            let expectation = self.customExpectation(description: "Notification fired")
            token = NotificationInContext.addObserver(
                name: ZMConversation.failedToSendMessageNotificationName,
                context: self.uiMOC.notificationContext,
                object: nil
            ) { _ in
                expectation.fulfill()
            }
        }

        // THEN
        withExtendedLifetime(token) {
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItMarksAnImageMessageAsSentWhenItReceivesASuccesfulResponse() {
        // GIVEN
        var message: ZMAssetClientMessage!
        mockMessageSender.sendMessageMessage_MockMethod = { _ in }
        syncMOC.performGroupedAndWait {
            message = self.createMessage(uploaded: true, assetId: true)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedAndWait {
            XCTAssert(message.delivered)
            XCTAssertEqual(message.deliveryState, .sent)
        }
    }

    // MARK: Fileprivate

    fileprivate var mockMessageSender: MockMessageSenderInterface!
    fileprivate var sut: AssetClientMessageRequestStrategy!
    fileprivate var imageData = mediumJPEGData()
}
