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
@testable import WireMessageStrategy


class AssetV3ImageUploadRequestStrategyTests: MessagingTest {

    fileprivate var registrationStatus: MockClientRegistrationStatus!
    fileprivate var sut : AssetV3ImageUploadRequestStrategy!
    fileprivate var conversation: ZMConversation!
    fileprivate var imageData = mediumJPEGData()

    override func setUp() {
        super.setUp()
        registrationStatus = MockClientRegistrationStatus()
        sut = AssetV3ImageUploadRequestStrategy(clientRegistrationStatus: registrationStatus, managedObjectContext: syncMOC)
        conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        createSelfClient()
    }

    // MARK: - Helpers

    func createImageFileMessage(ephemeral: Bool = false) -> ZMAssetClientMessage {
        conversation.messageDestructionTimeout = ephemeral ? 10 : 0
        let message = conversation.appendMessage(withImageData: imageData, version3: true)
        syncMOC.saveOrRollback()
        return message as! ZMAssetClientMessage
    }

    func createPreprocessedV2ImageMessage() -> ZMAssetClientMessage {
        let message = conversation.appendOTRMessage(withImageData: verySmallJPEGData(), nonce: .create(), version3: false)
        let properties = ZMIImageProperties(size: message.imageAssetStorage!.originalImageSize(), length: 1000, mimeType: "image/jpg")
        message.imageAssetStorage?.setImageData(message.imageAssetStorage?.originalImageData(), for: .medium, properties: properties)
        message.imageAssetStorage?.setImageData(message.imageAssetStorage?.originalImageData(), for: .preview, properties: properties)
        syncMOC.saveOrRollback()
        return message
    }

    func simulatePreprocessing(of message: ZMAssetClientMessage) {
        let size = CGSize(width: 368, height: 520)
        let properties = ZMIImageProperties(size: size, length: 1024, mimeType: "image/jpg")
        message.imageAssetStorage?.setImageData(imageData, for: .medium, properties: properties)
        XCTAssertEqual(message.mimeType, "image/jpg")
        XCTAssertEqual(message.size, 1024)
        XCTAssertEqual(message.imageMessageData?.originalSize, size)
    }

    func prepareUpload(of message: ZMAssetClientMessage) {
        ZMChangeTrackerBootstrap.bootStrapChangeTrackers(sut.contextChangeTrackers, on: syncMOC)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: – Request Generation

    func testThatItDoesNotGenerateARequestWhenTheImageIsNotProcessed() {
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotGenerateARequestIfTheImageIsProcessedButTheMessageIsNotV3() {
        // given
        let message = createPreprocessedV2ImageMessage()

        // then
        prepareUpload(of: message)
        XCTAssertNil(sut.nextRequest())

        // when
        message.uploadState = .uploadingFullAsset

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItGeneratesARequestIfTheImageIsProcessed() {
        // given
        let message = createImageFileMessage()

        // when
        simulatePreprocessing(of: message)
        prepareUpload(of: message)

        // then
        guard let request = sut.nextRequest() else { return XCTFail("No request created") }
        XCTAssertEqual(request.path, "/assets/v3")

    }

    func testThatItPreprocessesTheImageAndDeletesTheOriginalDataAfterwards() {
        // given
        let message = createImageFileMessage()

        // when
        XCTAssert(ZMAssetClientMessage.v3_imageProcessingFilter.evaluate(with: message))
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true))
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: false))

        sut.contextChangeTrackers.forEach {
            $0.objectsDidChange(Set(arrayLiteral: message))
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let original = syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .original, encrypted: false)
        let mediumEncrypted = syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true)
        let mediumPlain = syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: false)

        XCTAssertNil(original)
        XCTAssertNotNil(mediumEncrypted)
        XCTAssertNotNil(mediumPlain)
        guard let assetData = message.genericAssetMessage?.assetData else { return XCTFail("No assetData") }
        XCTAssertTrue(assetData.hasUploaded())
        XCTAssertTrue(assetData.uploaded.hasOtrKey())
        XCTAssertTrue(assetData.uploaded.hasSha256())
    }

    // MARK: – Request Response Parsing

    func testThatItUpdatesTheMessageWithTheAssetIdAndTokenFromTheResponse() {
        XCTFail()
    }

    func testThatItCleansUpCorrectlyIfTheRequestResponseIsNotSuccesfull() {
        XCTFail()
    }

    // MARK: – Ephemeral

    func testThatItGeneratesARequest_Ephemeral() {
        XCTFail()
    }

    func testThatItPreprocessesV3ImageMessage_Ephemeral() {
        XCTFail()
    }

}


