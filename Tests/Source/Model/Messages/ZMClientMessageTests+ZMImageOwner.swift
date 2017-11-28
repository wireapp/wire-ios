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
import WireLinkPreview

@testable import WireDataModel

enum ContentType {
    case textMessage, editMessage
}

class ClientMessageTests_ZMImageOwner: BaseZMClientMessageTests {
        
    func insertMessageWithLinkPreview(contentType: ContentType) -> ZMClientMessage {
        let clientMessage = ZMClientMessage.insertNewObject(in: uiMOC)
        let nonce = UUID()
        let article = Article(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 12
        )
        article.title = "title"
        article.summary = "tile"
        let text = "sample text"
        var genericMessage : ZMGenericMessage!
        switch contentType{
        case .textMessage:
            genericMessage = ZMGenericMessage.message(text: text, linkPreview: article.protocolBuffer, nonce: nonce.transportString())
        case .editMessage:
            genericMessage = ZMGenericMessage(editMessage: UUID.create().transportString(), newText: text, linkPreview: article.protocolBuffer, nonce: nonce.transportString())
        }
        clientMessage.add(genericMessage.data())
        clientMessage.nonce = nonce
        return clientMessage
    }
    
    func testThatItCachesAndEncryptsTheMediumImage_TextMessage() {
        // given
        let clientMessage = insertMessageWithLinkPreview(contentType: .textMessage)
        let imageData = mediumJPEGData()
        
        // when
        let properties = ZMIImageProperties(size: CGSize(width: 42, height: 12), length: UInt(imageData.count), mimeType: "image/jpeg")
        clientMessage.setImageData(imageData, for: .medium, properties: properties)
        
        // then
        XCTAssertNotNil(self.uiMOC.zm_imageAssetCache.assetData(clientMessage.nonce, format: .medium, encrypted: false))
        XCTAssertNotNil(self.uiMOC.zm_imageAssetCache.assetData(clientMessage.nonce, format: .medium, encrypted: true))
        
        guard let linkPreview = clientMessage.genericMessage?.linkPreviews.first else { return XCTFail("did not contain linkpreview") }
        XCTAssertNotNil(linkPreview.article.image.uploaded.otrKey)
        XCTAssertNotNil(linkPreview.article.image.uploaded.sha256)

        let original = linkPreview.article.image.original!
        XCTAssertEqual(Int(original.size), imageData.count)
        XCTAssertEqual(original.mimeType, "image/jpeg")
        XCTAssertEqual(original.image.width, 42)
        XCTAssertEqual(original.image.height, 12)
        XCTAssertFalse(original.hasName())
    }
    
    func testThatItCachesAndEncryptsTheMediumImage_EditMessage() {
        // given
        let clientMessage = insertMessageWithLinkPreview(contentType: .editMessage)
        let imageData = mediumJPEGData()
        
        // when
        let properties = ZMIImageProperties(size: CGSize(width: 42, height: 12), length: UInt(imageData.count), mimeType: "image/jpeg")
        clientMessage.setImageData(imageData, for: .medium, properties: properties)
        
        // then
        XCTAssertNotNil(self.uiMOC.zm_imageAssetCache.assetData(clientMessage.nonce, format: .medium, encrypted: false))
        XCTAssertNotNil(self.uiMOC.zm_imageAssetCache.assetData(clientMessage.nonce, format: .medium, encrypted: true))
        
        guard let linkPreview = clientMessage.genericMessage?.linkPreviews.first else { return XCTFail("did not contain linkpreview") }
        XCTAssertNotNil(linkPreview.article.image.uploaded.otrKey)
        XCTAssertNotNil(linkPreview.article.image.uploaded.sha256)
        
        let original = linkPreview.article.image.original!
        XCTAssertEqual(Int(original.size), imageData.count)
        XCTAssertEqual(original.mimeType, "image/jpeg")
        XCTAssertEqual(original.image.width, 42)
        XCTAssertEqual(original.image.height, 12)
        XCTAssertFalse(original.hasName())
    }
    
    func testThatUpdatesLinkPreviewStateAndDeleteOriginalDataAfterProcessingFinishes() {
        // given
        let nonce = UUID()
        let clientMessage = ZMClientMessage.insertNewObject(in: uiMOC)
        clientMessage.nonce = nonce
        self.uiMOC.zm_imageAssetCache.storeAssetData(nonce, format: .original, encrypted: false, data: mediumJPEGData())
        
        // when
        clientMessage.processingDidFinish()
        
        // then
        XCTAssertEqual(clientMessage.linkPreviewState, ZMLinkPreviewState.processed)
        XCTAssertNil(self.uiMOC.zm_imageAssetCache.assetData(nonce, format: .original, encrypted: false))
    }
    
    func testThatItReturnsCorrectOriginalImageSize() {
        // given
        let nonce = UUID()
        let clientMessage = ZMClientMessage.insertNewObject(in: uiMOC)
        clientMessage.nonce = nonce
        self.uiMOC.zm_imageAssetCache.storeAssetData(nonce, format: .original, encrypted: false, data: mediumJPEGData())
        
        // when
        let imageSize = clientMessage.originalImageSize()
        
        // then
        XCTAssertEqual(imageSize, CGSize(width: 1352, height:1803))
    }
    
}

