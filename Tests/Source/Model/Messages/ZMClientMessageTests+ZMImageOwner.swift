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
import ZMCLinkPreview

@testable import ZMCDataModel

class ClientMessageTests_ZMImageOwner: BaseZMClientMessageTests {
    
    override func setUp() {
        super.setUp()
        self.setUpCaches()
    }
    
    func testThatItCachesAndEncryptsTheMediumImage() {
        // given
        let clientMessage = ZMClientMessage.insertNewObjectInManagedObjectContext(syncMOC)
        let nonce = NSUUID()
        let article = Article(
            originalURLString: "example.com/article/original",
            permamentURLString: "http://www.example.com/article/1",
            offset: 12
        )
        article.title = "title"
        article.summary = "tile"
        clientMessage.addData(ZMGenericMessage(text: "sample text", linkPreview: article.protocolBuffer, nonce: nonce.transportString()).data())
        clientMessage.nonce = nonce
        let imageData = mediumJPEGData()
        
        // when
        let properties = ZMIImageProperties(size: CGSize(width: 42, height: 12), length: UInt(imageData.length), mimeType: "image/jpeg")
        clientMessage.setImageData(imageData, forFormat: .Medium, properties: properties)
        
        // then
        XCTAssertNotNil(self.syncMOC.zm_imageAssetCache.assetData(clientMessage.nonce, format: .Medium, encrypted: false))
        XCTAssertNotNil(self.syncMOC.zm_imageAssetCache.assetData(clientMessage.nonce, format: .Medium, encrypted: true))
        
        let linkPreview = clientMessage.genericMessage?.text.linkPreview.first as! ZMLinkPreview
        XCTAssertNotNil(linkPreview.article.image.uploaded.otrKey)
        XCTAssertNotNil(linkPreview.article.image.uploaded.sha256)

        let original = linkPreview.article.image.original
        XCTAssertEqual(Int(original.size), imageData.length)
        XCTAssertEqual(original.mimeType, "image/jpeg")
        XCTAssertEqual(original.image.width, 42)
        XCTAssertEqual(original.image.height, 12)
        XCTAssertFalse(original.hasName())
    }
    
    func testThatUpdatesLinkPreviewStateAndDeleteOriginalDataAfterProcessingFinishes() {
        // given
        let nonce = NSUUID()
        let clientMessage = ZMClientMessage.insertNewObjectInManagedObjectContext(syncMOC)
        clientMessage.nonce = nonce
        self.syncMOC.zm_imageAssetCache.storeAssetData(nonce, format: .Original, encrypted: false, data: mediumJPEGData())
        
        // when
        clientMessage.processingDidFinish()
        
        // then
        XCTAssertEqual(clientMessage.linkPreviewState, ZMLinkPreviewState.Processed)
        XCTAssertNil(self.syncMOC.zm_imageAssetCache.assetData(nonce, format: .Original, encrypted: false))
    }
    
    func testThatItReturnsCorrectOriginalImageSize() {
        // given
        let nonce = NSUUID()
        let clientMessage = ZMClientMessage.insertNewObjectInManagedObjectContext(syncMOC)
        clientMessage.nonce = nonce
        self.syncMOC.zm_imageAssetCache.storeAssetData(nonce, format: .Original, encrypted: false, data: mediumJPEGData())
        
        // when
        let imageSize = clientMessage.originalImageSize()
        
        // then
        XCTAssertEqual(imageSize, CGSizeMake(1352, 1803))
    }
    
}
