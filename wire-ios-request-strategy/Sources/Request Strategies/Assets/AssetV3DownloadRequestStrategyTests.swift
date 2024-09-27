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
import WireTransport
import XCTest
@testable import WireRequestStrategy

private let testDataURL = Bundle(for: AssetV3DownloadRequestStrategyTests.self).url(
    forResource: "Lorem Ipsum",
    withExtension: "txt"
)!

// MARK: - MockTaskCancellationProvider

public class MockTaskCancellationProvider: NSObject, ZMRequestCancellation {
    // MARK: Lifecycle

    deinit {
        cancelledIdentifiers.removeAll()
    }

    // MARK: Public

    public func cancelTask(with identifier: ZMTaskIdentifier) {
        cancelledIdentifiers.append(identifier)
    }

    // MARK: Internal

    var cancelledIdentifiers = [ZMTaskIdentifier]()
}

// MARK: - AssetV3DownloadRequestStrategyTests

final class AssetV3DownloadRequestStrategyTests: MessagingTestBase {
    // MARK: Internal

    var mockApplicationStatus: MockApplicationStatus!
    var sut: AssetV3DownloadRequestStrategy!
    var conversation: ZMConversation!
    var user: ZMUser!

    var apiVersion: APIVersion! {
        didSet {
            BackendInfo.apiVersion = apiVersion
        }
    }

    override func setUp() {
        super.setUp()

        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        sut = AssetV3DownloadRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus
        )

        syncMOC.performGroupedAndWait {
            self.user = self.createUser(alsoCreateClient: true)
            self.conversation = self.createGroupConversation(with: self.user)
        }

        apiVersion = .v0
    }

    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        user = nil
        conversation = nil
        super.tearDown()
    }

    func testThatItMarksMessageAsDownloading_WhenRequestingFileDownload() {
        var assetMessage: ZMAssetClientMessage!
        syncMOC.performGroupedAndWait {
            // Given
            guard let (message, _, _, _) = self.createFileMessageWithAssetId(in: self.conversation)
            else { return XCTFail("No message") }
            assetMessage = message

            // When
            message.requestFileDownload()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // Then
            XCTAssertTrue(assetMessage.isDownloading)
        }
    }

    func testThatItDoesNotMarksMessageAsDownloading_WhenRequestingFileDownloadIfFileIsAlreadyDownloaded() {
        var assetMessage: ZMAssetClientMessage!
        syncMOC.performGroupedAndWait {
            // Given
            guard let (message, _, _, _) = self.createFileMessageWithAssetId(in: self.conversation)
            else { return XCTFail("No message") }
            self.syncMOC.zm_fileAssetCache.storeOriginalFile(data: Data(), for: message)
            assetMessage = message

            // When
            message.requestFileDownload()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // Then
            XCTAssertFalse(assetMessage.isDownloading)
        }
    }

    func testThatItGeneratesAnExpectedV3RequestToTheV3EndpointIfTheProtobufContainsAnAssetID() {
        var expectedAssetId = ""
        syncMOC.performGroupedAndWait {
            // Given
            guard let (message, assetId, token, domain) = self.createFileMessageWithAssetId(in: self.conversation)
            else { return XCTFail("No message") }
            guard let assetData = message.underlyingMessage?.assetData else { return XCTFail("No assetData found") }

            expectedAssetId = assetId
            XCTAssert(assetData.hasUploaded)
            XCTAssertEqual(assetData.uploaded.assetID, assetId)
            XCTAssertEqual(assetData.uploaded.assetToken, token)
            XCTAssertFalse(assetData.uploaded.hasAssetDomain)
            XCTAssertNil(domain)
            message.requestFileDownload()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // When
            guard let request = self.sut.nextRequest(for: self.apiVersion)
            else { return XCTFail("No request generated") }

            // Then
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.path, "/assets/v3/\(expectedAssetId)")
            XCTAssert(request.needsAuthentication)
        }
    }

    func testThatItGeneratesAnExpectedV3RequestToTheV3EndpointITheProtobufContainsAnAssetID_EphemeralConversation() {
        var expectedAssetId = ""
        syncMOC.performGroupedAndWait {
            // Given
            self.conversation.setMessageDestructionTimeoutValue(.custom(5), for: .selfUser)
            guard let (message, assetId, token, domain) = self.createFileMessageWithAssetId(in: self.conversation)
            else { return XCTFail("No message") }
            guard let assetData = message.underlyingMessage?.assetData else { return XCTFail("No assetData found") }

            expectedAssetId = assetId
            XCTAssert(assetData.hasUploaded)
            XCTAssertEqual(assetData.uploaded.assetID, assetId)
            XCTAssertEqual(assetData.uploaded.assetToken, token)
            XCTAssertFalse(assetData.uploaded.hasAssetDomain)
            XCTAssertNil(domain)
            guard case .ephemeral? = message.underlyingMessage!.content else {
                return XCTFail("Ephemeral's message content is invalid")
            }
            message.requestFileDownload()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // When
            guard let request = self.sut.nextRequest(for: self.apiVersion)
            else { return XCTFail("No request generated") }

            // Then
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.path, "/assets/v3/\(expectedAssetId)")
            XCTAssert(request.needsAuthentication)
        }
    }

    func testThatItGeneratesAnExpectedV4RequestToTheV3EndpointIfTheProtobufContainsAnAssetID() {
        apiVersion = .v1

        var expectedAssetId = ""
        var expectedDomain: String! = ""
        syncMOC.performGroupedAndWait {
            // Given
            guard let (message, assetId, token, domain) = self.createFileMessageWithAssetId(in: self.conversation)
            else { return XCTFail("No message") }
            guard let assetData = message.underlyingMessage?.assetData else { return XCTFail("No assetData found") }

            expectedAssetId = assetId
            expectedDomain = domain
            XCTAssert(assetData.hasUploaded)
            XCTAssertEqual(assetData.uploaded.assetID, assetId)
            XCTAssertEqual(assetData.uploaded.assetToken, token)
            XCTAssertEqual(assetData.uploaded.assetDomain, domain!)
            message.requestFileDownload()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // When
            guard let request = self.sut.nextRequest(for: self.apiVersion)
            else { return XCTFail("No request generated") }

            // Then
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.path, "/v1/assets/v4/\(expectedDomain!)/\(expectedAssetId)")
            XCTAssert(request.needsAuthentication)
        }
    }

    func testThatItGeneratesAnExpectedV4RequestToTheV3EndpointITheProtobufContainsAnAssetID_EphemeralConversation_whenFederationIsEnabled(
    ) {
        apiVersion = .v1

        var expectedAssetId = ""
        var expectedDomain: String! = ""
        syncMOC.performGroupedAndWait {
            // Given
            self.conversation.setMessageDestructionTimeoutValue(.custom(5), for: .selfUser)
            guard let (message, assetId, token, domain) = self.createFileMessageWithAssetId(in: self.conversation)
            else { return XCTFail("No message") }
            guard let assetData = message.underlyingMessage?.assetData else { return XCTFail("No assetData found") }

            expectedAssetId = assetId
            expectedDomain = domain
            XCTAssert(assetData.hasUploaded)
            XCTAssertEqual(assetData.uploaded.assetID, assetId)
            XCTAssertEqual(assetData.uploaded.assetToken, token)
            XCTAssertEqual(assetData.uploaded.assetDomain, domain!)
            guard case .ephemeral? = message.underlyingMessage!.content else {
                return XCTFail("content missing")
            }
            message.requestFileDownload()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // When
            guard let request = self.sut.nextRequest(for: self.apiVersion)
            else { return XCTFail("No request generated") }

            // Then
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.path, "/v1/assets/v4/\(expectedDomain!)/\(expectedAssetId)")
            XCTAssert(request.needsAuthentication)
        }
    }

    func testThatItGeneratesNoRequestsIfITheProtobufDoesNotContainUploaded() {
        syncMOC.performGroupedAndWait {
            // Given
            let message = try! self.conversation
                .appendFile(with: ZMFileMetadata(fileURL: testDataURL)) as! ZMAssetClientMessage
            message.updateTransferState(.uploaded, synchronize: false)
            self.deleteDownloadedFileFor(message: message)
            self.syncMOC.saveOrRollback()
            message.requestFileDownload()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // Then
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatItGeneratesNoRequestsIfMessageIsUploading_V3() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            guard let (message, _, _, _) = self.createFileMessageWithAssetId(in: self.conversation) else {
                return XCTFail("Failed to create message")
            } // V3
            message.updateTransferState(.uploading, synchronize: false)
            message.requestFileDownload()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // THEN
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    // MARK: Fileprivate

    fileprivate func createFileMessageWithAssetId(
        in conversation: ZMConversation,
        otrKey: Data = Data.randomEncryptionKey(),
        sha: Data = Data.randomEncryptionKey()
    ) -> (message: ZMAssetClientMessage, assetId: String, assetToken: String, domain: String?)? {
        let isFederationEnabled = apiVersion > .v0
        let message = try! conversation.appendFile(with: ZMFileMetadata(fileURL: testDataURL)) as! ZMAssetClientMessage
        let messageDomain = isFederationEnabled ? UUID.create().transportString() : nil
        let (assetId, token, domain) = (UUID.create().transportString(), UUID.create().transportString(), messageDomain)
        let content = WireProtos.Asset(withUploadedOTRKey: otrKey, sha256: sha)
        var uploaded = GenericMessage(
            content: content,
            nonce: message.nonce!,
            expiresAfter: conversation.activeMessageDestructionTimeoutValue
        )

        uploaded.updateUploaded(assetId: assetId, token: token, domain: domain)
        message.updateTransferState(.uploaded, synchronize: false)

        do {
            try message.setUnderlyingMessage(uploaded)
        } catch {
            XCTFail("Could not set generic message")
        }

        deleteDownloadedFileFor(message: message)
        XCTAssertEqual(message.version, 3)
        syncMOC.saveOrRollback()
        return (message, assetId, token, domain)
    }

    fileprivate func deleteDownloadedFileFor(message: ZMAssetClientMessage) {
        coreDataStack.viewContext.zm_fileAssetCache.deleteAssetData(message)
        coreDataStack.syncContext.zm_fileAssetCache.deleteAssetData(message)
    }
}

// tests on result of request
extension AssetV3DownloadRequestStrategyTests {
    func testThatItMarksDownloadAsSuccessIfSuccessfulDownloadAndDecryption_V3() throws {
        // GIVEN
        let plainTextData = Data.secureRandomData(length: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = try plainTextData.zmEncryptPrefixingPlainTextIV(key: key)

        var message: ZMMessage!
        syncMOC.performGroupedAndWait {
            let sha = encryptedData.zmSHA256Digest()
            let (msg, _, _, _) = self.createFileMessageWithAssetId(in: self.conversation, otrKey: key, sha: sha)!
            msg.requestFileDownload()
            message = msg
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            let response = ZMTransportResponse(
                imageData: encryptedData,
                httpStatus: 200,
                transportSessionError: .none,
                headers: [:],
                apiVersion: self.apiVersion.rawValue
            )

            // WHEN
            request?.complete(with: response)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // THEN
            XCTAssertEqual(message.fileMessageData?.downloadState, .downloaded)
        }
    }

    func testThatItDeletesMessageIfItCannotDownload_PermanentError_V3() {
        let message: ZMAssetClientMessage = syncMOC.performGroupedAndWait {
            // GIVEN
            let (msg, _, _, _) = self.createFileMessageWithAssetId(in: self.conversation)!
            msg.requestFileDownload()
            return msg
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            let response = ZMTransportResponse(
                payload: [] as ZMTransportData,
                httpStatus: 404,
                transportSessionError: .none,
                apiVersion: self.apiVersion.rawValue
            )

            // WHEN
            request?.complete(with: response)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // THEN
            XCTAssertTrue(message.isZombieObject)
        }
    }

    // When the backend redirects to the cloud service to get the image, it could be that the
    // network bandwidth of the device is really bad. If the time interval is pretty long before
    // the connectivity returns, the cloud responds with an error having status code 403
    // -> retry the image request and do not delete the asset client message.
    func testThatItMarksDownloadAsFailedIfCannotDownload_TemporaryError_403_V3() {
        let message: ZMAssetClientMessage = syncMOC.performGroupedAndWait {
            // GIVEN
            let (msg, _, _, _) = self.createFileMessageWithAssetId(in: self.conversation)!
            msg.requestFileDownload()
            return msg
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            let response = ZMTransportResponse(
                payload: [] as ZMTransportData,
                httpStatus: 403,
                transportSessionError: nil,
                apiVersion: self.apiVersion.rawValue
            )

            // WHEN
            request?.complete(with: response)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // THEN
            XCTAssertEqual(message.fileMessageData?.downloadState, .remote)
        }
    }

    func testThatItMarksDownloadAsFailedIfCannotDownload_TemporaryError_500_V3() {
        let message: ZMAssetClientMessage = syncMOC.performGroupedAndWait {
            // GIVEN
            let (msg, _, _, _) = self.createFileMessageWithAssetId(in: self.conversation)!
            msg.requestFileDownload()
            return msg
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            let response = ZMTransportResponse(
                payload: [] as ZMTransportData,
                httpStatus: 500,
                transportSessionError: nil,
                apiVersion: self.apiVersion.rawValue
            )

            // WHEN
            request?.complete(with: response)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // THEN
            XCTAssertEqual(message.fileMessageData?.downloadState, .remote)
        }
    }

    func testThatItMarksDownloadAsFailedIfCannotDownload_CannotDecrypt_V3() {
        // GIVEN
        var message: ZMMessage!
        syncMOC.performGroupedAndWait {
            let (msg, _, _, _) = self.createFileMessageWithAssetId(in: self.conversation)!
            msg.requestFileDownload()
            message = msg
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // WHEN
        performIgnoringZMLogError {
            self.syncMOC.performGroupedAndWait {
                let request = self.sut.nextRequest(for: self.apiVersion)
                let response = ZMTransportResponse(
                    payload: [] as ZMTransportData,
                    httpStatus: 200,
                    transportSessionError: .none,
                    apiVersion: self.apiVersion.rawValue
                )
                request?.complete(with: response)
            }
            XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // THEN
        syncMOC.performGroupedAndWait {
            XCTAssertTrue(message.isZombieObject)
        }
    }

    func testThatItUpdatesFileDownloadProgress_V3() {
        var message: ZMMessage!
        let expectedProgress: Float = 0.5

        // GIVEN
        syncMOC.performGroupedAndWait {
            let (msg, _, _, _) = self.createFileMessageWithAssetId(in: self.conversation)!
            msg.requestFileDownload()
            message = msg
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // WHEN
        syncMOC.performGroupedAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            XCTAssertEqual(message.fileMessageData?.progress, 0)
            request?.updateProgress(expectedProgress)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedAndWait {
            XCTAssertEqual(message.fileMessageData?.progress, expectedProgress)
        }
    }

    func testThatItSendsNonCoreDataChangeNotification_AfterSuccessfullyDownloadingAsset() throws {
        // GIVEN
        let plainTextData = Data.secureRandomData(length: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = try plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        var message: ZMAssetClientMessage!

        syncMOC.performGroupedAndWait {
            message = self.createFileMessageWithAssetId(in: self.conversation, otrKey: key, sha: sha)!.message
            message.requestFileDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // EXPECT
        var token: Any?
        let expectation = customExpectation(description: "Notification fired")
        token = NotificationInContext.addObserver(
            name: .NonCoreDataChangeInManagedObject,
            context: uiMOC.notificationContext,
            object: nil
        ) { note in

            XCTAssertEqual(note.changedKeys, [#keyPath(ZMAssetClientMessage.hasDownloadedFile)])
            expectation.fulfill()
        }

        // WHEN
        syncMOC.performGroupedAndWait {
            guard let request = self.sut.nextRequest(for: self.apiVersion)
            else { return XCTFail("Did not create expected request") }
            request.markStartOfUploadTimestamp()
            let response = ZMTransportResponse(
                imageData: encryptedData,
                httpStatus: 200,
                transportSessionError: .none,
                headers: [:],
                apiVersion: self.apiVersion.rawValue
            )

            request.complete(with: response)
        }

        // THEN
        withExtendedLifetime(token) {
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItRecategorizeMessageAfterDownloadingAssetContent() throws {
        let plainTextData = verySmallJPEGData()
        let key = Data.randomEncryptionKey()
        let encryptedData = try plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        let messageId = UUID.create()

        var message: ZMAssetClientMessage!
        syncMOC.performGroupedAndWait {
            // GIVEN
            var asset = WireProtos.Asset()
            var imageMetaData = WireProtos.Asset.ImageMetaData(width: 100, height: 100)
            imageMetaData.tag = "medium"
            asset.original = WireProtos.Asset.Original(
                withSize: UInt64(plainTextData.count),
                mimeType: "image/jpeg",
                name: nil,
                imageMetaData: imageMetaData
            )
            asset.uploaded = WireProtos.Asset.RemoteData(
                withOTRKey: key,
                sha256: sha,
                assetId: "someId",
                assetToken: "someToken"
            )

            let genericMessage = GenericMessage(content: asset, nonce: messageId)
            let messageData = try! genericMessage.serializedData()

            let dict = [
                "recipient": self.selfClient.remoteIdentifier!,
                "sender": self.selfClient.remoteIdentifier!,
                "text": messageData.base64String(),
            ] as NSDictionary

            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: [
                "type": "conversation.otr-message-add",
                "data": dict,
                "from": self.selfClient.user!.remoteIdentifier!,
                "conversation": self.conversation.remoteIdentifier!.transportString(),
                "time": Date(timeIntervalSince1970: 555_555).transportString(),
            ] as NSDictionary, uuid: nil)!

            message = ZMOTRMessage.createOrUpdate(
                from: updateEvent,
                in: self.syncMOC,
                prefetchResult: nil
            ) as? ZMAssetClientMessage
            message.visibleInConversation = self.conversation
            message.updateTransferState(.uploaded, synchronize: false)
            self.syncMOC.saveOrRollback()
            message.requestFileDownload()

            XCTAssertEqual(message.category, [.image, .excludedFromCollection])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            for tracker in self.sut.contextChangeTrackers {
                tracker.objectsDidChange([message])
            }

            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.markStartOfUploadTimestamp()
            let response = ZMTransportResponse(
                imageData: encryptedData,
                httpStatus: 200,
                transportSessionError: .none,
                headers: [:],
                apiVersion: self.apiVersion.rawValue
            )

            // WHEN
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // THEN
            XCTAssertEqual(message.category, [.image])
        }
    }

    func testThatItRecategorizeMessageWithSvgAttachmentAfterDownloadingAssetContent() throws {
        guard let plainTextData = (
            "<svg width=\"100\" height=\"100\">"
                + "<rect width=\"100\" height=\"100\"/>"
                + "</svg>"
        ).data(using: .utf8) else {
            XCTFail("Unable to convert SVG to Data")
            return
        }

        let key = Data.randomEncryptionKey()
        let encryptedData = try plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        let messageId = UUID.create()

        var message: ZMAssetClientMessage!
        syncMOC.performGroupedAndWait {
            // GIVEN
            var asset = WireProtos.Asset()
            var imageMetaData = WireProtos.Asset.ImageMetaData(width: 100, height: 100)
            imageMetaData.tag = "medium"
            asset.original = WireProtos.Asset.Original(
                withSize: UInt64(plainTextData.count),
                mimeType: "image/svg+xml",
                name: nil,
                imageMetaData: imageMetaData
            ) // Even if we treat them as files, SVGs are sent as images.
            asset.uploaded = WireProtos.Asset.RemoteData(
                withOTRKey: key,
                sha256: sha,
                assetId: "someId",
                assetToken: "someToken"
            )

            let genericMessage = GenericMessage(content: asset, nonce: messageId)
            let messageData = try! genericMessage.serializedData()

            let dict = [
                "recipient": self.selfClient.remoteIdentifier!,
                "sender": self.selfClient.remoteIdentifier!,
                "text": messageData.base64String(),
            ] as NSDictionary

            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: [
                "type": "conversation.otr-message-add",
                "data": dict,
                "from": self.selfClient.user!.remoteIdentifier!,
                "conversation": self.conversation.remoteIdentifier!.transportString(),
                "time": Date(timeIntervalSince1970: 555_555).transportString(),
            ] as NSDictionary, uuid: nil)!

            message = ZMOTRMessage.createOrUpdate(
                from: updateEvent,
                in: self.syncMOC,
                prefetchResult: nil
            ) as? ZMAssetClientMessage
            message.visibleInConversation = self.conversation
            message.updateTransferState(.uploaded, synchronize: false)
            self.syncMOC.saveOrRollback()
            message.requestFileDownload()

            XCTAssertEqual(message.category, [.file])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.markStartOfUploadTimestamp()
            let response = ZMTransportResponse(
                imageData: encryptedData,
                httpStatus: 200,
                transportSessionError: .none,
                headers: [:],
                apiVersion: self.apiVersion.rawValue
            )

            // WHEN
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // THEN
            XCTAssertEqual(message.category, [.file])
        }
    }
}

// MARK: - Download Cancellation

extension AssetV3DownloadRequestStrategyTests {
    func testThatItInformsTheTaskCancellationProviderToCancelARequestForAnAssetMessageWhenItReceivesTheNotification_V3(
    ) {
        var message: ZMAssetClientMessage!
        var identifier: ZMTaskIdentifier?

        // GIVEN
        syncMOC.performGroupedAndWait {
            let (msg, _, _, _) = self.createFileMessageWithAssetId(in: self.conversation)!
            msg.requestFileDownload()
            message = msg
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            //  task has been created
            guard let request = self.sut.nextRequest(for: self.apiVersion) else { return XCTFail("No request created") }

            request.callTaskCreationHandlers(withIdentifier: 42, sessionIdentifier: self.name)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            identifier = message.associatedTaskIdentifier
        }
        XCTAssertNotNil(identifier)

        // WHEN the transfer is cancelled
        syncMOC.performGroupedBlock {
            message.fileMessageData?.cancelTransfer()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // THEN the cancellation provider should be informed to cancel the request
            XCTAssertEqual(self.mockApplicationStatus.cancelledIdentifiers.count, 1)
            let cancelledIdentifier = self.mockApplicationStatus.cancelledIdentifiers.first
            XCTAssertEqual(cancelledIdentifier, identifier)

            // It should nil-out the identifier as it has been cancelled
            XCTAssertNil(message.associatedTaskIdentifier)
        }
    }
}
