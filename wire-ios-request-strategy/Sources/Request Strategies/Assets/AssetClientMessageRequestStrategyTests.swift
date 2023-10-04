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
import XCTest
import WireDataModel

fileprivate extension ZMTransportRequest {

    func complete(withHttpStatus status: Int, apiVersion: APIVersion) {
        let payload = ["time": Date().transportString()] as ZMTransportData
        let response = ZMTransportResponse(payload: payload, httpStatus: status, transportSessionError: nil, apiVersion: apiVersion.rawValue)
        complete(with: response)
    }

}

final class AssetClientMessageRequestStrategyTests: MessagingTestBase {

    fileprivate var mockApplicationStatus: MockApplicationStatus!
    fileprivate var sut: AssetClientMessageRequestStrategy!
    fileprivate var imageData = mediumJPEGData()

    var apiVersion: APIVersion! {
        didSet {
            setCurrentAPIVersion(apiVersion)
        }
    }

    override func setUp() {
        super.setUp()

        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online

        self.syncMOC.performGroupedBlockAndWait {
            self.sut = AssetClientMessageRequestStrategy(withManagedObjectContext: self.syncMOC, applicationStatus: self.mockApplicationStatus)
        }

        apiVersion = .v0
    }

    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        apiVersion = nil
        super.tearDown()
    }

    // MARK: Helper

    @discardableResult func createMessage(
        isImage: Bool = true,
        uploaded: Bool = false,
        preview: Bool = false,
        assetId: Bool = false,
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
            let url = Bundle(for: AssetClientMessageRequestStrategyTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!
            message = try! targetConversation.appendFile(with: ZMFileMetadata(fileURL: url, thumbnail: nil)) as? ZMAssetClientMessage
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
            let previewAsset = WireProtos.Asset.Preview(size: 128,
                                                        mimeType: "image/jpg",
                                                        remoteData: remote,
                                                        imageMetadata: imageMetadata)

            let previewMessage = GenericMessage(
                content: WireProtos.Asset(original: nil, preview: previewAsset),
                nonce: message.nonce!,
                expiresAfter: targetConversation.activeMessageDestructionTimeoutValue
            )

            XCTAssertNoThrow(try message.setUnderlyingMessage(previewMessage))

            XCTAssertTrue(message.underlyingMessage!.assetData!.hasPreview, line: line)
            XCTAssertEqual(message.underlyingMessage!.assetData!.preview.remote.hasAssetID, previewAssetId, line: line)
            XCTAssertEqual(message.isEphemeral, targetConversation.activeMessageDestructionTimeoutValue != nil, line: line)
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
            XCTAssertEqual(message.isEphemeral, self.groupConversation.activeMessageDestructionTimeoutValue != nil, line: line)
        } else {
            message.updateTransferState(transferState, synchronize: true) // TODO jacob
        }

        if let sender = sender {
            message.sender = sender
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

    @discardableResult
    private func assertCreatesValidRequestForAsset(in conversation: ZMConversation, line: UInt = #line) async -> ZMTransportRequest! {
        switch apiVersion! {
        case .v0:
            guard let request = await sut.nextRequest(for: self.apiVersion) else {
                XCTFail("No request generated", line: line)
                return nil
            }

            let converationID = conversation.remoteIdentifier!.transportString()

            XCTAssertEqual(request.path, "/conversations/\(converationID)/otr/messages", line: line)
            XCTAssertEqual(request.method, .methodPOST, line: line)
            return request

        case .v1, .v2, .v3, .v4, .v5:
            guard let request = await sut.nextRequest(for: self.apiVersion) else {
                XCTFail("No request generated", line: line)
                return nil
            }

            let domain = conversation.domain!
            let conversationID = conversation.remoteIdentifier!.transportString()

            XCTAssertEqual(request.path, "/v\(apiVersion.rawValue)/conversations/\(domain)/\(conversationID)/proteus/messages", line: line)
            XCTAssertEqual(request.method, .methodPOST, line: line)
            return request
        }
    }

    // MARK: Request Generation

    func testThatItDoesNotCreateARequestIfThereIsNoMatchingMessage() async {
        let result = await sut.nextRequest(for: apiVersion)
        XCTAssertNil(result)
    }

    func testThatItDoesNotCreateARequestForAnImageMessageUploadedByOtherUser() async {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.createMessage(uploaded: true, sender: self.otherUser)
        }

        // THEN
        let result = await self.sut.nextRequest(for: self.apiVersion)
        XCTAssertNil(result)

    }

    func testThatItDoesNotCreateARequestForAnImageMessageWhichIsExpired() async {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let message = self.createMessage(uploaded: true)
            message.expire()
        }

        // THEN
        let result = await self.sut.nextRequest(for: self.apiVersion)
        XCTAssertNil(result)
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithoutUploaded() async {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.createMessage(uploaded: false)
        }

        // THEN
        let result = await self.sut.nextRequest(for: self.apiVersion)
        XCTAssertNil(result)
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithUploadedAndAssetIdInTheWrongTransferState() async {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let message = self.createMessage()
            message.updateTransferState(.uploaded, synchronize: true)
        }
        // THEN
        let result = await self.sut.nextRequest(for: self.apiVersion)
        XCTAssertNil(result)
    }

    func testThatItCreatesARequestForAnUploadedImageMessage() async {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.createMessage(uploaded: true, assetId: true)
        }

        // THEN
        await self.assertCreatesValidRequestForAsset(in: self.groupConversation)
    }

    func testThatItCreatesARequestForAnUploadedImageMessage_WithFederationEndpointEnabled() async {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.apiVersion = .v1
            self.createMessage(uploaded: true, assetId: true)
        }

        // THEN
        await self.assertCreatesValidRequestForAsset(in: self.groupConversation)
    }

    func testThatItCreatesARequestForAnUploadedImageMessage_Ephemeral() async {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.groupConversation.setMessageDestructionTimeoutValue(.custom(15), for: .selfUser)
            self.createMessage(uploaded: true, assetId: true)
        }
        // WHEN
        guard let request = await self.sut.nextRequest(for: self.apiVersion) else { return XCTFail("No request generated") }

        // THEN
        let expected = "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages"
        XCTAssertEqual(request.path, expected)
        XCTAssertEqual(request.method, .methodPOST)
    }

    func testThatItUpdatesExpectsReadConfirmationFlagWhenSendingMessageInOneToOne() async {
        var objectID: NSManagedObjectID?
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            ZMUser.selfUser(in: self.syncMOC).readReceiptsEnabled = true
            let message = self.createMessage(isImage: true, uploaded: true, assetId: true, conversation: self.oneToOneConversation)
            objectID = message.objectID
        }
        // WHEN
        let result = await self.sut.nextRequest(for: self.apiVersion)
        XCTAssertNotNil(result)

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let messageObjectId = objectID,
                  let message = try? self.syncMOC.existingObject(with: messageObjectId) as? ZMAssetClientMessage else {
                XCTFail("no message object available")
                return
            }

            switch message.underlyingMessage?.content {
            case .asset(let data)?:
                XCTAssertTrue(data.expectsReadConfirmation)
            default:
                XCTFail("Unexpected message content")
            }
        }
    }

    func testThatItDoesntUpdateExpectsReadConfirmationFlagWhenSendingMessageInGroup() async {
        var objectID: NSManagedObjectID?
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            ZMUser.selfUser(in: self.syncMOC).readReceiptsEnabled = true
            let message = self.createMessage(isImage: true, uploaded: true, assetId: true, conversation: self.groupConversation)
            objectID = message.objectID
        }
        // WHEN
        let result = await self.sut.nextRequest(for: self.apiVersion)
        XCTAssertNotNil(result)

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let messageObjectId = objectID,
                  let message = try? self.syncMOC.existingObject(with: messageObjectId) as? ZMAssetClientMessage else {
                XCTFail("no message object available")
                return
            }

            switch message.underlyingMessage?.content {
            case .asset(let data)?:
                XCTAssertFalse(data.expectsReadConfirmation)
            default:
                XCTFail("Unexpected message content")
            }
        }
    }

    func testThatItUpdateExpectsReadConfirmationFlagWhenReadReceiptsAreDisabled() async {
        var objectID: NSManagedObjectID?
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            ZMUser.selfUser(in: self.syncMOC).readReceiptsEnabled = false
            let message = self.createMessage(isImage: true, uploaded: true, assetId: true, conversation: self.oneToOneConversation)
            objectID = message.objectID

            var genericMessage = message.underlyingMessage!
            genericMessage.setExpectsReadConfirmation(true)

            do {
                try message.setUnderlyingMessage(genericMessage)
            } catch {
                XCTFail("Could not set generic message")
            }
        }

        // WHEN
        let result = await self.sut.nextRequest(for: self.apiVersion)
        XCTAssertNotNil(result)

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let messageObjectId = objectID,
                  let message = try? self.syncMOC.existingObject(with: messageObjectId) as? ZMAssetClientMessage else {
                XCTFail("no message object available")
                return
            }
            XCTAssertFalse(message.underlyingMessage!.asset.expectsReadConfirmation)
        }
    }

    func testThatItUpdateExpectsReadConfirmationFlagWhenReadReceiptsAreEnabled() async {
        var objectID: NSManagedObjectID?

        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            ZMUser.selfUser(in: self.syncMOC).readReceiptsEnabled = true
            let message = self.createMessage(isImage: true, uploaded: true, assetId: true, conversation: self.oneToOneConversation)
            var genericMessage = message.underlyingMessage!
            genericMessage.setExpectsReadConfirmation(true)
            objectID = message.objectID
            do {
                try message.setUnderlyingMessage(genericMessage)
            } catch {
                XCTFail("Could not set generic message")
            }
        }
        // WHEN
        let result = await self.sut.nextRequest(for: self.apiVersion)
        XCTAssertNotNil(result)

            // THEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let messageObjectId = objectID,
                  let message = try? self.syncMOC.existingObject(with: messageObjectId) as? ZMAssetClientMessage else {
                XCTFail("no message object available")
                return
            }

            XCTAssertTrue(message.underlyingMessage!.asset.expectsReadConfirmation)
        }
    }

    func testThatItUpdatesLegalHoldStatusFlagWhenLegalHoldIsEnabled() async {
        var objectID: NSManagedObjectID?

        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let legalHoldClient = UserClient.insertNewObject(in: self.syncMOC)
            legalHoldClient.deviceClass = .legalHold
            legalHoldClient.type = .legalHold
            legalHoldClient.user = self.otherUser

            let conversation = self.groupConversation!
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [legalHoldClient], causedBy: [self.otherUser])
            XCTAssertTrue(conversation.isUnderLegalHold)

            let message = self.createMessage(isImage: true, uploaded: true, assetId: true, conversation: self.groupConversation)
            objectID = message.objectID
            var genericMessage = message.underlyingMessage!
            genericMessage.setLegalHoldStatus(.enabled)

            do {
                try message.setUnderlyingMessage(genericMessage)
            } catch {
                XCTFail("Could not set generic message")
            }

            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
        }

        let result = await self.sut.nextRequest(for: self.apiVersion)
        XCTAssertNotNil(result, "request should not be nil")

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let messageObjectId = objectID,
                  let message = try? self.syncMOC.existingObject(with: messageObjectId) as? ZMAssetClientMessage else {
                XCTFail("no message object available")
                return
            }

            XCTAssertEqual(message.underlyingMessage!.asset.legalHoldStatus, .enabled)
        }
    }

    func testThatItUpdatesLegalHoldStatusFlagWhenLegalHoldIsDisabled() async {
        var objectID: NSManagedObjectID?
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let conversation = self.groupConversation!
            XCTAssertFalse(conversation.isUnderLegalHold)

            let message = self.createMessage(isImage: true, uploaded: true, assetId: true, conversation: self.groupConversation)
            objectID = message.objectID
            var genericMessage = message.underlyingMessage!
            genericMessage.setLegalHoldStatus(.enabled)

            do {
                try message.setUnderlyingMessage(genericMessage)
            } catch {
                XCTFail("Could not set generic message")
            }

            self.syncMOC.saveOrRollback()
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
        }

        // WHEN
        let result = await self.sut.nextRequest(for: self.apiVersion)

        // THEN
        XCTAssertNotNil(result)
        self.syncMOC.performGroupedBlockAndWait {
            guard let messageObjectId = objectID,
                  let message = try? self.syncMOC.existingObject(with: messageObjectId) as? ZMAssetClientMessage else {
                XCTFail("no message object available")
                return
            }

            XCTAssertEqual(message.underlyingMessage!.asset.legalHoldStatus, .disabled)
        }
    }

    // MARK: Response handling

    func testThatItExpiresAMessageWhenItReceivesAFailureResponse() async {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(uploaded: true, assetId: true)
        }

        // WHEN
        guard let request = await self.assertCreatesValidRequestForAsset(in: self.groupConversation) else {
            return XCTFail("Failed to create request")
        }


        self.syncMOC.performGroupedBlockAndWait {
            request.complete(withHttpStatus: 400, apiVersion: self.apiVersion)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssert(message.isExpired)
            XCTAssertEqual(message.deliveryState, .failedToSend)
        }

        let result = await self.sut.nextRequest(for: self.apiVersion)
        XCTAssertNil(result)

    }

    func testThatItNotifiesWhenAnImageCannotBeSent_MissingLegalholdConsent() async {
        // GIVEN
        var token: Any?
        self.syncMOC.performGroupedBlockAndWait {
            let message = self.createMessage(uploaded: true, assetId: true)
            let expectation = self.expectation(description: "Notification fired")
            token = NotificationInContext.addObserver(name: ZMConversation.failedToSendMessageNotificationName,
                                                      context: self.uiMOC.notificationContext,
                                                      object: nil) {_ in
                expectation.fulfill()
            }
        }

        // WHEN
        guard let request = await self.assertCreatesValidRequestForAsset(in: self.groupConversation) else {
            return XCTFail("Failed to create request")
        }

        self.syncMOC.performGroupedBlockAndWait {
            let payload = ["label": "missing-legalhold-consent", "code": 403, "message": ""] as NSDictionary
            request.complete(with: ZMTransportResponse(payload: payload, httpStatus: 403, transportSessionError: nil, apiVersion: self.apiVersion.rawValue))
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        withExtendedLifetime(token) { () -> Void in
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItMarksAnImageMessageAsSentWhenItReceivesASuccesfulResponse() async {

        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(uploaded: true, assetId: true)
        }

        // WHEN
        guard let request = await self.assertCreatesValidRequestForAsset(in: self.groupConversation)
            else { return XCTFail("No request generated") }

        self.syncMOC.performGroupedBlockAndWait {
            request.complete(withHttpStatus: 200, apiVersion: self.apiVersion)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssert(message.delivered)
            XCTAssertEqual(message.deliveryState, .sent)
        }

        let result = await self.sut.nextRequest(for: self.apiVersion)
        XCTAssertNil(result)
    }

    func testThatItMarksAnImageMessageAsSentWhenItReceivesASuccesfulResponse_Ephemeral() async {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            self.groupConversation.setMessageDestructionTimeoutValue(.custom(15), for: .selfUser)
            message = self.createMessage(uploaded: true, assetId: true)
        }

        // WHEN
        guard let request = await self.sut.nextRequest(for: self.apiVersion)
            else { return XCTFail("No request generated") }

        self.syncMOC.performGroupedBlockAndWait {
            request.complete(withHttpStatus: 200, apiVersion: self.apiVersion)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {

            XCTAssert(message.delivered)
            XCTAssertEqual(message.deliveryState, .sent)
        }
        
        let result = await self.sut.nextRequest(for: self.apiVersion)
        XCTAssertNil(result)
    }

}
