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
import GenericMessageProtocol
import WireDataModel
import WireTransport
import XCTest

@testable import WireRequestStrategy

class LinkPreviewAssetDownloadRequestStrategyTests: MessagingTestBase {

    var sut: LinkPreviewAssetDownloadRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var oneToOneconversationOnSync: ZMConversation!

    override func setUp() {
        super.setUp()

        syncMOC.performGroupedAndWait {
            self.mockApplicationStatus = MockApplicationStatus()
            self.mockApplicationStatus.mockSynchronizationState = .online
            self.oneToOneconversationOnSync = syncMOC
                .object(with: self.oneToOneConversation.objectID) as? ZMConversation

            self.sut = LinkPreviewAssetDownloadRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: self.mockApplicationStatus,
                localDomain: "wire.com"
            )
        }
    }

    override func tearDown() {
        syncMOC.performGroupedAndWait {
            self.sut = nil
            self.mockApplicationStatus = nil
            self.oneToOneconversationOnSync = nil
            try? syncMOC.zm_fileAssetCache.wipeCaches()
        }
        try? uiMOC.zm_fileAssetCache.wipeCaches()
        super.tearDown()
    }

    // MARK: - Helper

    fileprivate func createLinkPreview(
        _ assetID: String,
        _ assetDomain: String? = nil,
        article: Bool = true,
        otrKey: Data? = nil,
        sha256: Data? = nil
    ) -> LinkPreview {
        let URL = "http://www.example.com"

        if article {
            let (otr, sha) = (otrKey ?? Data.randomEncryptionKey(), sha256 ?? Data.zmRandomSHA256Key())
            let remoteData = GenericMessageProtocol.Asset.RemoteData.with {
                $0.assetID = assetID
                if let assetDomain {
                    $0.assetDomain = assetDomain
                }
                $0.otrKey = otr
                $0.sha256 = sha
            }
            let asset = GenericMessageProtocol.Asset.with {
                $0.uploaded = remoteData
            }
            return LinkPreview.with {
                $0.url = URL
                $0.permanentURL = URL
                $0.urlOffset = 42
                $0.title = "Title"
                $0.summary = "Summary"
                $0.image = asset
            }
        } else {
            return LinkPreview.with {
                $0.url = URL
                $0.permanentURL = URL
                $0.urlOffset = 42
                $0.title = "Title"
                $0.tweet = GenericMessageProtocol.Tweet.with {
                    $0.author = "Author"
                    $0.username = "UserName"
                }
            }
        }
    }

    fileprivate func fireSyncCompletedNotification() {
        // ManagedObjectContextObserver does not process all changes until the sync is done
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: "ZMApplicationDidEnterEventProcessingStateNotification"),
            object: nil,
            userInfo: nil
        )
    }
}

extension LinkPreviewAssetDownloadRequestStrategyTests {

    // MARK: - Request Generation

    func testThatItGeneratesAnExpectedV3RequestForAWhitelistedMessageWithNoImageInCache() {
        // GIVEN
        let apiVersion: APIVersion = .v0
        let assetID = UUID.create().transportString()
        let linkPreview = createLinkPreview(assetID)
        let nonce = UUID.create()
        var text = Text(content: name, mentions: [], linkPreviews: [], replyingTo: nil)
        text.linkPreview.append(linkPreview)
        let genericMessage = GenericMessage(content: text, nonce: nonce)

        syncMOC.performGroupedAndWait {
            let message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        syncMOC.performGroupedAndWait {
            // THEN
            guard let request = self.sut.nextRequest(for: apiVersion)
            else { XCTFail("No request generated"); return }
            XCTAssertEqual(request.path, "/assets/v3/\(assetID)")
            XCTAssertEqual(request.method, .get)
            XCTAssertNil(self.sut.nextRequest(for: apiVersion))
        }
    }

    func testThatItGeneratesAnExpectedV3RequestForAWhitelistedEphemeralMessageWithNoImageInCache() {
        let apiVersion: APIVersion = .v0
        let assetID = UUID.create().transportString()

        syncMOC.performGroupedAndWait {
            // GIVEN
            let linkPreview = self.createLinkPreview(assetID)
            let nonce = UUID.create()
            var text = Text(content: self.name, mentions: [], linkPreviews: [], replyingTo: nil)
            text.linkPreview.append(linkPreview)
            let genericMessage = GenericMessage(content: text, nonce: nonce, expiresAfterTimeInterval: 20)
            let message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        syncMOC.performGroupedAndWait {
            // THEN
            guard let request = self.sut.nextRequest(for: apiVersion)
            else { XCTFail("No request generated"); return }
            XCTAssertEqual(request.path, "/assets/v3/\(assetID)")
            XCTAssertEqual(request.method, .get)
            XCTAssertNil(self.sut.nextRequest(for: apiVersion))
        }
    }

    func testThatItGeneratesAnExpectedV4RequestForAWhitelistedMessageWithNoImageInCache() {
        // GIVEN
        let apiVersion: APIVersion = .v1
        let assetID = UUID.create().transportString()
        let assetDomain = UUID().create().transportString()
        let linkPreview = createLinkPreview(assetID, assetDomain)
        let nonce = UUID.create()
        var text = Text(content: name, mentions: [], linkPreviews: [], replyingTo: nil)
        text.linkPreview.append(linkPreview)
        let genericMessage = GenericMessage(content: text, nonce: nonce)

        syncMOC.performGroupedAndWait {
            let message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        syncMOC.performGroupedAndWait {
            // THEN
            guard let request = self.sut.nextRequest(for: apiVersion)
            else { XCTFail("No request generated"); return }
            XCTAssertEqual(request.path, "/v1/assets/v4/\(assetDomain)/\(assetID)")
            XCTAssertEqual(request.method, .get)
            XCTAssertNil(self.sut.nextRequest(for: apiVersion))
        }
    }

    func testThatItGeneratesAnExpectedV4RequestForAWhitelistedEphemeralMessageWithNoImageInCache() {
        let apiVersion: APIVersion = .v1
        let assetID = UUID.create().transportString()
        let assetDomain = UUID().create().transportString()
        syncMOC.performGroupedAndWait {
            // GIVEN
            let linkPreview = self.createLinkPreview(assetID, assetDomain)
            let nonce = UUID.create()
            var text = Text(content: self.name, mentions: [], linkPreviews: [], replyingTo: nil)
            text.linkPreview.append(linkPreview)
            let genericMessage = GenericMessage(content: text, nonce: nonce, expiresAfterTimeInterval: 20)

            let message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        syncMOC.performGroupedAndWait {
            // THEN
            guard let request = self.sut.nextRequest(for: apiVersion)
            else { XCTFail("No request generated"); return }
            XCTAssertEqual(request.path, "/v1/assets/v4/\(assetDomain)/\(assetID)")
            XCTAssertEqual(request.method, .get)
            XCTAssertNil(self.sut.nextRequest(for: apiVersion))
        }
    }

    func testThatItDoesNotGenerateARequestForAMessageWithoutALinkPreview() {
        let apiVersion: APIVersion = .v0
        let message = syncMOC.performGroupedAndWait { () -> ZMMessage in
            let genericMessage = GenericMessage(content: Text(content: self.name))
            return try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
        }

        syncMOC.performGroupedAndWait {
            _ = try? self.syncMOC.obtainPermanentIDs(for: [message])
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // WHEN
        syncMOC.performGroupedAndWait {
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedAndWait {
            // THEN
            XCTAssertNil(self.sut.nextRequest(for: apiVersion))
        }
    }

    func testThatItDoesNotGenerateARequestForAMessageWithImageInCache() {
        let apiVersion: APIVersion = .v0
        syncMOC.performGroupedAndWait {
            // GIVEN
            let assetID = UUID.create().transportString()
            let linkPreview = self.createLinkPreview(assetID)
            let nonce = UUID.create()
            var text = Text(content: self.name, mentions: [], linkPreviews: [], replyingTo: nil)
            text.linkPreview.append(linkPreview)
            let genericMessage = GenericMessage(content: text, nonce: nonce)
            let message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])
            syncMOC.zm_fileAssetCache.storeMediumImage(data: .secureRandomData(length: 256), for: message)

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        syncMOC.performGroupedAndWait {
            // THEN
            XCTAssertNil(self.sut.nextRequest(for: apiVersion))
        }
    }

    func testThatItDoesNotGenerateARequestForAMessageWithoutArticleLinkPreview() {
        let apiVersion: APIVersion = .v0
        let assetID = UUID.create().transportString()
        let linkPreview = createLinkPreview(assetID, article: false)
        let nonce = UUID.create()
        var text = Text(content: name, mentions: [], linkPreviews: [], replyingTo: nil)
        text.linkPreview.append(linkPreview)
        let genericMessage = GenericMessage(content: text, nonce: nonce)
        var message: ZMMessage!

        syncMOC.performGroupedAndWait {
            // GIVEN
            message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])
            syncMOC.zm_fileAssetCache.storeMediumImage(data: .secureRandomData(length: 256), for: message)

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        syncMOC.performGroupedAndWait {
            // THEN
            XCTAssertNil(self.sut.nextRequest(for: apiVersion))
        }
    }

    // MARK: - Response Handling

    func testThatItStoresTheEncryptedImageDataInTheRequestResponse() throws {
        let apiVersion: APIVersion = .v0
        let assetID = UUID.create().transportString()
        let data = Data.secureRandomData(length: 256)
        let otrKey = Data.randomEncryptionKey()
        let encrypted = try data.zmEncryptPrefixingPlainTextIV(key: otrKey)
        let sha256 = encrypted.zmSHA256Digest()
        let linkPreview = createLinkPreview(assetID, otrKey: otrKey, sha256: sha256)
        let nonce = UUID.create()

        var text = Text(content: name, mentions: [], linkPreviews: [], replyingTo: nil)
        text.linkPreview.append(linkPreview)
        let genericMessage = GenericMessage(content: text, nonce: nonce)

        var message: ZMMessage!

        syncMOC.performGroupedAndWait {

            message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }
        syncMOC.performGroupedAndWait {
            // THEN
            guard let request = self.sut.nextRequest(for: apiVersion)
            else { XCTFail("No request generated"); return }
            let response = ZMTransportResponse(
                imageData: encrypted,
                httpStatus: 200,
                transportSessionError: nil,
                headers: nil,
                apiVersion: apiVersion.rawValue
            )

            // WHEN
            request.complete(with: response)
        }
        syncMOC.performGroupedAndWait {
            // THEN
            XCTAssertTrue(syncMOC.zm_fileAssetCache.hasEncryptedMediumImageData(for: message))
            XCTAssertFalse(syncMOC.zm_fileAssetCache.hasMediumImageData(for: message))
            let decryptedData = syncMOC.zm_fileAssetCache.decryptedMediumImageData(
                for: message,
                encryptionKey: otrKey,
                sha256Digest: sha256
            )
            XCTAssertEqual(decryptedData, data)
        }
    }

    func testThatItDoesNotDecyptTheImageDataInTheRequestResponseWhenTheResponseIsNotSuccessful() {
        let apiVersion: APIVersion = .v0
        let assetID = UUID.create().transportString()
        let linkPreview = createLinkPreview(assetID)
        let nonce = UUID.create()
        var text = Text(content: name, mentions: [], linkPreviews: [], replyingTo: nil)
        text.linkPreview.append(linkPreview)
        let genericMessage = GenericMessage(content: text, nonce: nonce)
        var message: ZMMessage!
        syncMOC.performGroupedAndWait {

            message = try! self.oneToOneconversationOnSync.appendClientMessage(with: genericMessage)
            _ = try? syncMOC.obtainPermanentIDs(for: [message])

            // WHEN
            message.textMessageData?.requestLinkPreviewImageDownload()
        }

        syncMOC.performGroupedAndWait {
            // THEN
            guard let request = self.sut.nextRequest(for: apiVersion)
            else { XCTFail("No request generated"); return }
            let response = ZMTransportResponse(
                imageData: .secureRandomData(length: 256),
                httpStatus: 400,
                transportSessionError: nil,
                headers: nil,
                apiVersion: apiVersion.rawValue
            )
            // WHEN
            request.complete(with: response)
        }
        syncMOC.performGroupedAndWait {
            // THEN
            XCTAssertNil(syncMOC.zm_fileAssetCache.mediumImageData(for: message))
            XCTAssertNil(syncMOC.zm_fileAssetCache.encryptedMediumImageData(for: message))
        }
    }
}
