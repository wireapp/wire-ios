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


import XCTest
import ZMCLinkPreview

@testable import ZMCDataModel

private class NotificationObserver: NSObject {
    
    let closure: NSNotification -> Void
    var token: NSObjectProtocol?
    
    init(name: String, closure: NSNotification -> Void) {
        self.closure = closure
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(notifcationReceived), name: name, object: nil)
    }
    
    @objc func notifcationReceived(note: NSNotification) {
        closure(note)
    }
    
    func tearDown() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

class ZMClientMessageTests_TextMessage: BaseZMMessageTests {
    
    override func setUp() {
        super.setUp()
        setUpCaches()
    }

    override func tearDown() {
        super.tearDown()
        wipeCaches()
    }

    func testThatItHasImageReturnsTrueWhenLinkPreviewWillContainAnImage() {
        // given
        let clientMessage = ZMClientMessage.insertNewObjectInManagedObjectContext(syncMOC)
        let nonce = NSUUID()
        let article = Article(
            originalURLString: "www.example.com/article/original",
            permamentURLString: "http://www.example.com/article/1",
            offset: 12
        )
        article.title = "title"
        article.summary = "summary"
        clientMessage.addData(ZMGenericMessage(text: "sample text", linkPreview: article.protocolBuffer.update(withOtrKey: NSData(), sha256: NSData()), nonce: nonce.transportString()).data())
        clientMessage.nonce = nonce
        
        // when
        let willHaveAnImage = clientMessage.textMessageData!.hasImageData
        
        // then
        XCTAssertTrue(willHaveAnImage)
    }
    
    func testThatItHasImageReturnsFalseWhenLinkPreviewDoesntContainAnImage() {
        
        // given
        let clientMessage = ZMClientMessage.insertNewObjectInManagedObjectContext(syncMOC)
        let nonce = NSUUID()
        let article = Article(
            originalURLString: "example.com/article/original",
            permamentURLString: "http://www.example.com/article/1",
            offset: 12
        )
        article.title = "title"
        article.summary = "summary"
        clientMessage.addData(ZMGenericMessage(text: "sample text", linkPreview: article.protocolBuffer, nonce: nonce.transportString()).data())
        clientMessage.nonce = nonce
        
        // when
        let willHaveAnImage = clientMessage.textMessageData!.hasImageData
        
        // then
        XCTAssertFalse(willHaveAnImage)
    }
    
    func testThatItHasImageReturnsTrueWhenLinkPreviewWillContainAnImage_TwitterStatus() {
        // given
        let clientMessage = ZMClientMessage.insertNewObjectInManagedObjectContext(syncMOC)
        let nonce = NSUUID.createUUID()
        let preview = TwitterStatus(
            originalURLString: "example.com/article/original",
            permamentURLString: "http://www.example.com/article/1",
            offset: 42
        )
        
        preview.author = "Author"
        preview.message = name

        let updated = preview.protocolBuffer.update(withOtrKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key())
        clientMessage.addData(ZMGenericMessage(text: "Text", linkPreview: updated, nonce: nonce.transportString()).data())
        clientMessage.nonce = nonce
        
        // when
        let willHaveAnImage = clientMessage.textMessageData!.hasImageData
        
        // then
        XCTAssertTrue(willHaveAnImage)
    }
    
    func testThatItHasImageReturnsFalseWhenLinkPreviewDoesntContainAnImage_TwitterStatus() {
        // given
        let clientMessage = ZMClientMessage.insertNewObjectInManagedObjectContext(syncMOC)
        let nonce = NSUUID.createUUID()
        let preview = TwitterStatus(
            originalURLString: "example.com/article/original",
            permamentURLString: "http://www.example.com/article/1",
            offset: 42
        )
        
        preview.author = "Author"
        preview.message = name
        clientMessage.addData(ZMGenericMessage(text: "Text", linkPreview: preview.protocolBuffer, nonce: nonce.transportString()).data())
        clientMessage.nonce = nonce
        
        // when
        let willHaveAnImage = clientMessage.textMessageData!.hasImageData
        
        // then
        XCTAssertFalse(willHaveAnImage)
    }
    
    func testThatItHasImageReturnsTrueIfTheImageIsNotYetProcessedButTheOriginalIsInTheCache() {
        // given
        let clientMessage = ZMClientMessage.insertNewObjectInManagedObjectContext(syncMOC)
        let nonce = NSUUID.createUUID()
        let preview = TwitterStatus(
            originalURLString: "example.com/article/original",
            permamentURLString: "http://www.example.com/article/1",
            offset: 42
        )
        
        preview.author = "Author"
        preview.message = name
        let genericMessage = ZMGenericMessage(text: "Text", linkPreview: preview.protocolBuffer, nonce: nonce.transportString())
        clientMessage.addData(genericMessage.data())
        clientMessage.nonce = nonce
        syncMOC.zm_imageAssetCache.storeAssetData(nonce, format: .Original, encrypted: false, data: .secureRandomDataOfLength(256))
        
        // when
        let willHaveAnImage = clientMessage.textMessageData!.hasImageData
        
        // then
        XCTAssertTrue(willHaveAnImage)
    }
    
    func testThatItReturnsImageDataIdentifier_whenArticleHasImage() {
        // given
        let clientMessage = ZMClientMessage.insertNewObjectInManagedObjectContext(syncMOC)
        let nonce = NSUUID.createUUID()
        let article = Article(
            originalURLString: "example.com/article/original",
            permamentURLString: "http://www.example.com/article/1",
            offset: 12
        )

        article.title = "title"
        article.summary = "summary"
        let assetKey = "123"

        let linkPreview = article.protocolBuffer.update(withOtrKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key()).update(withAssetKey: assetKey, assetToken: nil)
        clientMessage.addData(ZMGenericMessage(text: "sample text", linkPreview: linkPreview, nonce: nonce.transportString()).data())
        clientMessage.nonce = nonce
        
        // when
        let imageDataIdentifier = clientMessage.textMessageData!.imageDataIdentifier
        
        // then
        XCTAssertEqual(imageDataIdentifier, assetKey)
    }
    
    func testThatItDoesntReturnsImageDataIdentifier_whenArticleHasNoImage() {
        
        // given
        let clientMessage = ZMClientMessage.insertNewObjectInManagedObjectContext(syncMOC)
        let nonce = NSUUID()
        let article = Article(originalURLString: "example.com/article/original", permamentURLString: "http://www.example.com/article/1", offset: 12)
        article.title = "title"
        article.summary = "summary"
        clientMessage.addData(ZMGenericMessage(text: "sample text", linkPreview: article.protocolBuffer, nonce: nonce.transportString()).data())
        clientMessage.nonce = nonce
        
        // when
        let imageDataIdentifier = clientMessage.textMessageData!.imageDataIdentifier
        
        // then
        XCTAssertNil(imageDataIdentifier)
    }
    
    func testThatItReturnsImageDataIdentifier_whenTwitterStatusHasImage() {
        // given
        let clientMessage = ZMClientMessage.insertNewObjectInManagedObjectContext(syncMOC)
        let nonce = NSUUID.createUUID()
        let assetKey = "123"
        let twitterStatus = TwitterStatus(
            originalURLString: "example.com/tweet",
            permamentURLString: "http://www.example.com/tweet/1",
            offset: 42
        )
        
        twitterStatus.author = "Author"
        twitterStatus.message = name
        
        let linkPreview = twitterStatus.protocolBuffer.update(withOtrKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key()).update(withAssetKey: assetKey, assetToken: nil)
        clientMessage.addData(ZMGenericMessage(text: "Text", linkPreview: linkPreview, nonce: nonce.transportString()).data())
        clientMessage.nonce = nonce
        
        // when
        let imageDataIdentifier = clientMessage.textMessageData!.imageDataIdentifier
        
        // then
        XCTAssertEqual(imageDataIdentifier, assetKey)
    }
    
    func testThatItDoesntReturnsImageDataIdentifier_whenTwitterStatusHasNoImage() {
        // given
        let clientMessage = ZMClientMessage.insertNewObjectInManagedObjectContext(syncMOC)
        let nonce = NSUUID.createUUID()
        let preview = TwitterStatus(
            originalURLString: "example.com/tweet",
            permamentURLString: "http://www.example.com/tweet/1",
            offset: 42
        )
        
        preview.author = "Author"
        preview.message = name
        clientMessage.addData(ZMGenericMessage(text: "Text", linkPreview: preview.protocolBuffer, nonce: nonce.transportString()).data())
        clientMessage.nonce = nonce
        
        // when
        let imageDataIdentifier = clientMessage.textMessageData!.imageDataIdentifier
        
        // then
        XCTAssertNil(imageDataIdentifier)
    }
    
    
    
    func testThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalledAndItHasAAssetID() {
        // given
        let preview = TwitterStatus(
            originalURLString: "example.com/article/original",
            permamentURLString: "http://www.example.com/article/1",
            offset: 42
        )
        
        preview.author = "Author"
        preview.message = name
        
        // then
        assertThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalled(preview)
    }
    
    func testThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalledAndItHasAAssetID_Article() {
        // given
        let preview = Article(
            originalURLString: "example.com/article/original",
            permamentURLString: "http://www.example.com/article/1",
            offset: 42
        )
        
        preview.title = "title"
        preview.summary = "summary"
        
        // then
        assertThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalled(preview)
    }
    
    func assertThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalled(preview: LinkPreview, line: UInt = #line) {
        let expectation = expectationWithDescription("It should fire a notification")
        setUpCaches()
        
        // given
        let clientMessage = ZMClientMessage.insertNewObjectInManagedObjectContext(syncMOC)
        let nonce = NSUUID.createUUID()
        
        let updated = preview.protocolBuffer.update(withOtrKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key())
        let withID = updated.update(withAssetKey: "ID", assetToken: nil)
        clientMessage.addData(ZMGenericMessage(text: "Text", linkPreview: withID, nonce: nonce.transportString()).data())
        clientMessage.nonce = nonce
        try! syncMOC.obtainPermanentIDsForObjects([clientMessage])
        
        // when
        
        let observer = NotificationObserver(name: ZMClientMessageLinkPreviewImageDownloadNotificationName) { note in
            guard note.object as? NSManagedObjectID == clientMessage.objectID else { return XCTFail() }
            expectation.fulfill()
        }
        
        clientMessage.requestImageDownload()
        
        // then
        XCTAssertTrue(waitForCustomExpectationsWithTimeout(0.2), line: line)
        observer.tearDown()
    }
    

}
