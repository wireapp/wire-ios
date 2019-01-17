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
import WireLinkPreview

@testable import WireDataModel

class ZMClientMessageTests_TextMessage: BaseZMMessageTests {
    
    override func tearDown() {
        super.tearDown()
        wipeCaches()
    }

    func testThatItHasImageReturnsTrueWhenLinkPreviewWillContainAnImage() {
        // given
        let nonce = UUID()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)

        let article = ArticleMetadata(
            originalURLString: "www.example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 12
        )
        article.title = "title"
        article.summary = "summary"
        let linkPreview = article.protocolBuffer.update(withOtrKey: Data(), sha256: Data())
        clientMessage.add(ZMGenericMessage.message(content: ZMText.text(with: "sample text", linkPreviews: [linkPreview]), nonce: nonce).data())
        
        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage
        
        // then
        XCTAssertTrue(willHaveAnImage)
    }
    
    func testThatItHasImageReturnsFalseWhenLinkPreviewDoesntContainAnImage() {
        
        // given
        let nonce = UUID()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)

        let article = ArticleMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 12
        )
        article.title = "title"
        article.summary = "summary"
        clientMessage.add(ZMGenericMessage.message(content: ZMText.text(with: "sample text", linkPreviews: [article.protocolBuffer]), nonce: nonce).data())
        
        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage
        
        // then
        XCTAssertFalse(willHaveAnImage)
    }
    
    func testThatItHasImageReturnsTrueWhenLinkPreviewWillContainAnImage_TwitterStatus() {
        // given
        let nonce = UUID.create()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)

        let preview = TwitterStatusMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )
        
        preview.author = "Author"
        preview.message = name

        let updated = preview.protocolBuffer.update(withOtrKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key())
        clientMessage.add(ZMGenericMessage.message(content: ZMText.text(with: "Text", linkPreviews: [updated]), nonce: nonce).data())
        
        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage
        
        // then
        XCTAssertTrue(willHaveAnImage)
    }
    
    func testThatItHasImageReturnsFalseWhenLinkPreviewDoesntContainAnImage_TwitterStatus() {
        // given
        let nonce = UUID.create()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        

        let preview = TwitterStatusMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )
        
        preview.author = "Author"
        preview.message = name
        clientMessage.add(ZMGenericMessage.message(content: ZMText.text(with: "Text", linkPreviews: [preview.protocolBuffer]), nonce: nonce).data())
        
        // when
        let willHaveAnImage = clientMessage.textMessageData!.linkPreviewHasImage
        
        // then
        XCTAssertFalse(willHaveAnImage)
    }
    
    func testThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalledAndItHasAAssetID() {
        // given
        let preview = TwitterStatusMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )
        
        preview.author = "Author"
        preview.message = name
        
        // then
        assertThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalled(preview)
    }
    
    func testThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalledAndItHasAAssetID_Article() {
        // given
        let preview = ArticleMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 42
        )
        
        preview.title = "title"
        preview.summary = "summary"
        
        // then
        assertThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalled(preview)
    }
    
    func assertThatItSendsANotificationToDownloadTheImageWhenRequestImageDownloadIsCalled(_ preview: LinkMetadata, line: UInt = #line) {
        
        // given
        let nonce = UUID.create()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        
        let updated = preview.protocolBuffer.update(withOtrKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key())
        let withID = updated.update(withAssetKey: "id", assetToken: nil)
        clientMessage.add(ZMGenericMessage.message(content: ZMText.text(with: "Text", linkPreviews: [withID]), nonce: nonce).data())
        try! uiMOC.obtainPermanentIDs(for: [clientMessage])

        
        // when
        let expectation = self.expectation(description: "Notified")
        let token: Any? = NotificationInContext.addObserver(name: ZMClientMessage.linkPreviewImageDownloadNotification,
                                          context: self.uiMOC.notificationContext,
                                          object: clientMessage.objectID)
        { _ in
            expectation.fulfill()
        }
        
        clientMessage.textMessageData?.requestLinkPreviewImageDownload()
        
        // then
        withExtendedLifetime(token) { () -> () in
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.2), line: line)
        }
    }
    

}
