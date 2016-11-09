//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireRequestStrategy
@testable import WireMessageStrategy


class AssetClientMessageRequestStrategyTests: MessagingTest {

    fileprivate var clientRegistrationStatus: MockClientRegistrationStatus!
    fileprivate var sut: AssetClientMessageRequestStrategy!
    fileprivate var conversation: ZMConversation!
    fileprivate var otherUser: ZMUser!
    fileprivate var imageData = mediumJPEGData()

    override func setUp() {
        super.setUp()
        clientRegistrationStatus = MockClientRegistrationStatus()
        sut = AssetClientMessageRequestStrategy(clientRegistrationStatus: clientRegistrationStatus, managedObjectContext: syncMOC)
        createConversation()
        createSelfClient()
    }

    // MARK: Helper

    func createConversation() {
        conversation = .insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .oneOnOne
        conversation.connection = .insertNewObject(in: syncMOC)
        otherUser = .insertNewObject(in: syncMOC)
        conversation.connection?.to = otherUser
        otherUser.remoteIdentifier = .create()
    }

    @discardableResult func createMessage(isImage: Bool = true, uploaded: Bool = true, assetId: Bool = true) -> ZMAssetClientMessage {
        let message = conversation.appendMessage(withImageData: imageData, version3: true) as! ZMAssetClientMessage
        if isImage {
            let size = CGSize(width: 368, height: 520)
            let properties = ZMIImageProperties(size: size, length: 1024, mimeType: "image/jpg")
            message.imageAssetStorage?.setImageData(imageData, for: .medium, properties: properties)
            XCTAssertEqual(message.mimeType, "image/jpg")
            XCTAssertEqual(message.size, 1024)
            XCTAssertEqual(message.imageMessageData?.originalSize, size)
        }

        if uploaded {
            let (otr, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
            var uploaded = ZMGenericMessage.genericMessage(
                withUploadedOTRKey: otr,
                sha256: sha,
                messageID: message.nonce.transportString(),
                expiresAfter: NSNumber(value: conversation.messageDestructionTimeout)
            )
            if assetId {
                uploaded = uploaded.updated(withAssetId: UUID.create().transportString(), token: nil)!
            }
            message.add(uploaded)
            XCTAssertTrue(message.genericAssetMessage!.assetData!.hasUploaded())
            XCTAssertEqual(message.isEphemeral, conversation.messageDestructionTimeout != 0)
        }

        message.uploadState = .done
        message.transferState = .uploaded

        syncMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        prepareUpload(of: message)

        return message
    }

    func prepareUpload(of message: ZMAssetClientMessage) {
        ZMChangeTrackerBootstrap.bootStrapChangeTrackers(sut.contextChangeTrackers, on: syncMOC)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: Request Generation

    func testThatItDoesNotCreateARequestIfThereIsNoMatchingMessage() {
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithoutUploaded() {
        // given
        createMessage(uploaded: false)

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithUploadedButWithoutAssetId() {
        // given
        createMessage(uploaded: true, assetId: false)

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithUploadedAndAssetIdInTheWrongTransferState() {
        // given
        let message = createMessage()
        message.transferState = .uploading

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithUploadedAndAssetIdInTheWrongUploadedState() {
        // given
        let message = createMessage()
        message.uploadState = .uploadingFullAsset

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItCreatesARequestForAnUploadedImageMessage() {
        // given
        createMessage()

        // when
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }

        // then
        XCTAssertEqual(request.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/otr/messages")
        XCTAssertEqual(request.method, .methodPOST)
    }

    func testThatItCreatesARequestForAnUploadedImageMessage_Ephemeral() {
        // given
        conversation.messageDestructionTimeout = 15
        createMessage()

        // when
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }

        // then
        let expected = "/conversations/\(conversation.remoteIdentifier!.transportString())/otr/messages?report_missing=\(otherUser.remoteIdentifier!.transportString())"
        XCTAssertEqual(request.path, expected)
        XCTAssertEqual(request.method, .methodPOST)
    }

    // MARK: Response handling

    func testThatItMarksAnImageMessageAsSentWhenItReceivesASuccesfulResponse() {
        // given
        let message = createMessage()
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }

        // when
        let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil)
        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssert(message.delivered)
        XCTAssertEqual(message.deliveryState, .sent)
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItMarksAnImageMessageAsSentWhenItReceivesASuccesfulResponse_Ephemeral() {
        // given
        conversation.messageDestructionTimeout = 15
        let message = createMessage()
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }

        // when
        let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil)
        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssert(message.delivered)
        XCTAssertEqual(message.deliveryState, .sent)
        XCTAssertNil(sut.nextRequest())
    }

}
