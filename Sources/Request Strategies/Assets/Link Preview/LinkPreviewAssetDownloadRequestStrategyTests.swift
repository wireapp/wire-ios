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
import WireDataModel
import XCTest
import WireRequestStrategy


@testable import WireRequestStrategy

class LinkPreviewAssetDownloadRequestStrategyTests: MessagingTestBase {

    var sut: LinkPreviewAssetDownloadRequestStrategy!
    var mockApplicationStatus : MockApplicationStatus!
    var oneToOneconversationOnSync : ZMConversation!
    
    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .eventProcessing
        oneToOneconversationOnSync = syncMOC.object(with: oneToOneConversation.objectID) as! ZMConversation

        sut = LinkPreviewAssetDownloadRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: mockApplicationStatus)
    }
    
    override func tearDown() {
        sut = nil
        mockApplicationStatus = nil
        oneToOneconversationOnSync = nil
        syncMOC.zm_fileAssetCache.wipeCaches()
        uiMOC.zm_fileAssetCache.wipeCaches()
        super.tearDown()
    }
    
    // MARK: - Helper
    
    fileprivate func createLinkPreviewAndKeys(_ assetID: String, article: Bool = true, otrKey: Data? = nil, sha256: Data? = nil) -> (preview: ZMLinkPreview, otrKey: Data?, sha256: Data?) {
        let URL = "http://www.example.com"
        
        if article {
            let assetBuilder = ZMAsset.builder()!
            let remoteBuilder = ZMAssetRemoteData.builder()!
            let (otr, sha) = (otrKey ?? Data.randomEncryptionKey(), sha256 ?? Data.zmRandomSHA256Key())
            remoteBuilder.setAssetId(assetID)
            remoteBuilder.setOtrKey(otr)
            remoteBuilder.setSha256(sha)
            assetBuilder.setUploaded(remoteBuilder)
            let preview = ZMLinkPreview.linkPreview(withOriginalURL: URL, permanentURL: URL, offset: 42, title: "Title", summary: "Summary", imageAsset: assetBuilder.build(), tweet: nil)
            return (preview, otr, sha)
        } else {
            let tweet = ZMTweet.tweet(withAuthor: "Author", username: "UserName")
            let preview = ZMLinkPreview.linkPreview(withOriginalURL: URL, permanentURL: URL, offset: 42, title: "Title", summary: "Summary", imageAsset: nil, tweet: tweet)
            return (preview, nil, nil)
        }
    }
    
    fileprivate func fireSyncCompletedNotification() {
        // ManagedObjectContextObserver does not process all changes until the sync is done
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ZMApplicationDidEnterEventProcessingStateNotification"), object: nil, userInfo: nil)
    }
}

extension LinkPreviewAssetDownloadRequestStrategyTests {
    
    // MARK: - Request Generation

    func testThatItGeneratesARequestForAWhitelistedMessageWithNoImageInCache() {
        // GIVEN
        let assetID = UUID.create().transportString()
        let linkPreview = createLinkPreviewAndKeys(assetID).preview
        let nonce = UUID.create()
        let genericMessage = ZMGenericMessage.message(text: name!, linkPreview: linkPreview, nonce: nonce)
        let message = oneToOneconversationOnSync.appendClientMessage(with: genericMessage)!
        _ = try? syncMOC.obtainPermanentIDs(for: [message])
        
        // WHEN
        message.requestImageDownload()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }
        XCTAssertEqual(request.path, "/assets/v3/\(assetID)")
        XCTAssertEqual(request.method, ZMTransportRequestMethod.methodGET)
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItGeneratesARequestForAWhitelistedEphemeralMessageWithNoImageInCache() {
        // GIVEN
        let assetID = UUID.create().transportString()
        let linkPreview = createLinkPreviewAndKeys(assetID).preview
        let nonce = UUID.create()
        let genericMessage = ZMGenericMessage.message(text: name!, linkPreview: linkPreview, nonce: nonce, expiresAfter: NSNumber(value: 20))
        let message = oneToOneconversationOnSync.appendClientMessage(with: genericMessage)!
        _ = try? syncMOC.obtainPermanentIDs(for: [message])
        
        // WHEN
        message.requestImageDownload()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }
        XCTAssertEqual(request.path, "/assets/v3/\(assetID)")
        XCTAssertEqual(request.method, ZMTransportRequestMethod.methodGET)
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItDoesNotGenerateARequestForAMessageWithoutALinkPreview() {
        let genericMessage = ZMGenericMessage.message(text: name!, nonce: UUID.create())
        let message = oneToOneconversationOnSync.appendClientMessage(with: genericMessage)!
        _ = try? syncMOC.obtainPermanentIDs(for: [message])
        
        // WHEN
        message.requestImageDownload()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItDoesNotGenerateARequestForAMessageWithImageInCache() {
        // GIVEN
        let assetID = UUID.create().transportString()
        let linkPreview = createLinkPreviewAndKeys(assetID).preview
        let nonce = UUID.create()
        let genericMessage = ZMGenericMessage.message(text: name!, linkPreview: linkPreview, nonce: nonce)
        let message = oneToOneconversationOnSync.appendClientMessage(with: genericMessage)!
        _ = try? syncMOC.obtainPermanentIDs(for: [message])
        syncMOC.zm_fileAssetCache.storeAssetData(message, format: .medium, encrypted: false, data: .secureRandomData(length: 256))
        
        // WHEN
        message.requestImageDownload()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItDoesNotGenerateARequestForAMessageWithoutArticleLinkPreview() {
        // GIVEN
        let assetID = UUID.create().transportString()
        let linkPreview = createLinkPreviewAndKeys(assetID, article: false).preview
        let nonce = UUID.create()
        let genericMessage = ZMGenericMessage.message(text: name!, linkPreview: linkPreview, nonce: nonce)
        let message = oneToOneconversationOnSync.appendClientMessage(with: genericMessage)!
        _ = try? syncMOC.obtainPermanentIDs(for: [message])
        syncMOC.zm_fileAssetCache.storeAssetData(message, format: .medium, encrypted: false, data: .secureRandomData(length:256))
        
        // WHEN
        message.requestImageDownload()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertNil(sut.nextRequest())
    }
    
    // MARK: - Response Handling
    
    func testThatItDecryptsTheImageDataInTheRequestResponseAndDeletesTheEncryptedVersion() {
        let assetID = UUID.create().transportString()
        let data = Data.secureRandomData(length: 256)
        let otrKey = Data.randomEncryptionKey()
        let encrypted = data.zmEncryptPrefixingPlainTextIV(key: otrKey)
        let (linkPreview, _, _) = createLinkPreviewAndKeys(assetID, otrKey: otrKey, sha256: encrypted.zmSHA256Digest())
        let nonce = UUID.create()
        let genericMessage = ZMGenericMessage.message(text: name!, linkPreview: linkPreview, nonce: nonce)
        let message = oneToOneconversationOnSync.appendClientMessage(with: genericMessage)!
        _ = try? syncMOC.obtainPermanentIDs(for: [message])
        
        // WHEN
        message.requestImageDownload()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }
        let response = ZMTransportResponse(imageData: encrypted, httpStatus: 200, transportSessionError: nil, headers: nil)
        
        // WHEN
        request.complete(with: response)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        let actual = syncMOC.zm_fileAssetCache.assetData(message, format: .medium, encrypted: false)
        XCTAssertNotNil(actual)
        XCTAssertEqual(actual, data)
        XCTAssertNil(syncMOC.zm_fileAssetCache.assetData(message, format: .medium, encrypted: true))
    }
    
    func testThatItDoesNotDecyptTheImageDataInTheRequestResponseWhenTheResponseIsNotSuccessful() {
        let assetID = UUID.create().transportString()
        let (linkPreview, _, _) = createLinkPreviewAndKeys(assetID)
        let nonce = UUID.create()
        let genericMessage = ZMGenericMessage.message(text: name!, linkPreview: linkPreview, nonce: nonce)
        let message = oneToOneconversationOnSync.appendClientMessage(with: genericMessage)!
        _ = try? syncMOC.obtainPermanentIDs(for: [message])
        
        // WHEN
        message.requestImageDownload()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }
        let response = ZMTransportResponse(imageData: .secureRandomData(length:256), httpStatus: 400, transportSessionError: nil, headers: nil)
        
        // WHEN
        request.complete(with: response)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertNil(syncMOC.zm_fileAssetCache.assetData(message, format: .medium, encrypted: false))
        XCTAssertNil(syncMOC.zm_fileAssetCache.assetData(message, format: .medium, encrypted: true))
    }
}

