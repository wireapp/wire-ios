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
@testable import WireDataModel

class ZMGenericMessageTests_Obfuscation : ZMBaseManagedObjectTest {
    
    func assetWithImage() -> ZMAsset {
        let original = ZMAssetOriginal.original(withSize: 1000, mimeType: "image", name: "foo")
        let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data(), sha256: Data(), assetId: "id", assetToken: "token")
        let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 30, height: 40)
        let imageMetaDataBuilder = imageMetaData.toBuilder()!
        imageMetaDataBuilder.setTag("bar")
        
        let preview = ZMAssetPreview.preview(withSize: 2000, mimeType: "video", remoteData: remoteData, imageMetadata: imageMetaDataBuilder.build())
        let asset  = ZMAsset.asset(withOriginal: original, preview: preview)
        return asset
    }
    
    func testThatItObfuscatesEmojis(){
        // given
        let text = "📲"
        let message = ZMGenericMessage.message(content: ZMText.text(with: text), nonce: UUID.create(), expiresAfter: 1.0)
        
        // when
        let obfuscatedMessage = message.obfuscatedMessage()
        
        // then
        XCTAssertNotEqual(obfuscatedMessage?.text.content, text)
        XCTAssertNotNil(obfuscatedMessage?.hasText())
    }
    func testThatItObfuscatesCyrillic(){
        // given
        let text = "привет мир!"
        let message = ZMGenericMessage.message(content: ZMText.text(with: text), nonce: UUID.create(), expiresAfter: 1.0)
        
        // when
        let obfuscatedMessage = message.obfuscatedMessage()
        
        // then
        XCTAssertNotEqual(obfuscatedMessage?.text.content, text)
        XCTAssertNotNil(obfuscatedMessage?.hasText())
    }
    
    func testThatItObfuscatesTextMessages(){
        // given
        let text = "foo"
        let message = ZMGenericMessage.message(content: ZMText.text(with: text), nonce: UUID.create(), expiresAfter: 1.0)
        
        // when
        let obfuscatedMessage = message.obfuscatedMessage()
        
        // then
        XCTAssertNotEqual(obfuscatedMessage?.text.content, text)
        XCTAssertNotNil(obfuscatedMessage?.hasText())
    }
    
    func testThatItObfuscatesTextMessageDifferentlyEachTime() {
        // given
        let text = "foo"
        let message = ZMGenericMessage.message(content: ZMText.text(with: text), nonce: UUID.create(), expiresAfter: 1.0)
        
        // when
        let obfuscatedMessage1 = message.obfuscatedMessage()
        let obfuscatedMessage2 = message.obfuscatedMessage()
        
        // then
        XCTAssertNotNil(obfuscatedMessage1?.hasText())
        XCTAssertNotNil(obfuscatedMessage2?.hasText())
        XCTAssertNotEqual(obfuscatedMessage1?.text.content, text)
        XCTAssertNotEqual(obfuscatedMessage2?.text.content, text)
        XCTAssertNotEqual(obfuscatedMessage1?.text.content, obfuscatedMessage2?.text.content)
    }
    
    func testThatItDoesNotObfuscateNonEphemeralTextMessages(){
        // given
        let text = "foo"
        let message = ZMGenericMessage.message(content: ZMText.text(with: text), nonce: UUID.create())
        
        // when
        let obfuscatedMessage = message.obfuscatedMessage()
        
        // then
        XCTAssertNil(obfuscatedMessage)
    }
    
    func testThatItObfuscatesLinkPreviews(){
        // given
        let title = "title"
        let summary = "summary"
        let permURL = "www.example.com/permanent"
        let origURL = "www.example.com/original"
        let text = "foo www.example.com/original"
        let offset : Int32 = 4
        
        let linkPreview = ZMLinkPreview.linkPreview(withOriginalURL: origURL, permanentURL: permURL, offset: offset, title: title, summary: summary, imageAsset: nil)
        let genericMessage = ZMGenericMessage.message(content: ZMText.text(with: text, linkPreviews: [linkPreview]), nonce: UUID.create(), expiresAfter: 20.0)
        
        // when
        let obfuscated =  genericMessage.obfuscatedMessage()
        
        // then
        guard let obfuscatedLinkPreview = obfuscated?.linkPreviews.first else { return XCTFail()}
        
        // then
        let obfText = obfuscated!.text.content!
        let obfOrgURL = String(obfText[obfText.index(obfText.startIndex, offsetBy:4)...])
        XCTAssertNotEqual(obfuscatedLinkPreview.url, origURL)
        XCTAssertEqual(obfuscatedLinkPreview.url, obfOrgURL)
        XCTAssertEqual(obfuscatedLinkPreview.urlOffset, offset)
        XCTAssertTrue(obfuscatedLinkPreview.hasArticle())
        XCTAssertNotEqual(obfuscatedLinkPreview.article?.permanentUrl, permURL)
        XCTAssertNotEqual(obfuscatedLinkPreview.article?.permanentUrl.count, 0)
        XCTAssertNotEqual(obfuscatedLinkPreview.article?.title, title)
        XCTAssertNotEqual(obfuscatedLinkPreview.article?.title.count, 0)
        XCTAssertNotEqual(obfuscatedLinkPreview.article?.summary, summary)
        XCTAssertNotEqual(obfuscatedLinkPreview.article?.summary.count, 0)
    }
    
    func testThatItObfuscatesLinkPreviews_Images(){
        // given
        let title = "title"
        let summary = "summary"
        let permURL = "www.example.com/permanent"
        let origURL = "www.example.com/original"
        let text = "foo www.example.com/original"
        let image = assetWithImage()
        let offset : Int32 = 4

        let linkPreview = ZMLinkPreview.linkPreview(withOriginalURL: origURL, permanentURL: permURL, offset: offset, title: title, summary: summary, imageAsset: image)
        let genericMessage = ZMGenericMessage.message(content: ZMText.text(with: text, linkPreviews: [linkPreview]), nonce: UUID.create(), expiresAfter: 20.0)
        
        // when
        let obfuscated =  genericMessage.obfuscatedMessage()
        
        // then
        guard let obfuscatedLinkPreview = obfuscated?.linkPreviews.first else { return XCTFail()}
        guard let obfuscatedAsset = obfuscatedLinkPreview.image else {return XCTFail()}
        XCTAssertTrue(obfuscatedAsset.hasOriginal())
        XCTAssertEqual(obfuscatedAsset.original.size, 10)
        XCTAssertEqual(obfuscatedAsset.original.mimeType, "image")
        XCTAssertEqual(obfuscatedAsset.preview.size, 10)
        XCTAssertEqual(obfuscatedAsset.preview.mimeType, "video")
        XCTAssertEqual(obfuscatedAsset.preview.image.width, 30)
        XCTAssertEqual(obfuscatedAsset.preview.image.height, 40)
        XCTAssertEqual(obfuscatedAsset.preview.image.tag, "bar")
        XCTAssertFalse(obfuscatedAsset.preview.hasRemote())
    }
    
    func testThatItObfuscatesLinkPreviews_Tweets(){
        // given
        let title = "title"
        let summary = "summary"
        let permURL = "www.example.com/permanent"
        let origURL = "www.example.com/original"
        let text = "foo www.example.com/original"
        let tweet = ZMTweet.tweet(withAuthor: "author", username: "username")
        let offset : Int32 = 4
        
        let linkPreview = ZMLinkPreview.linkPreview(withOriginalURL: origURL, permanentURL: permURL, offset: offset, title: title, summary: summary, imageAsset: nil, tweet: tweet)
        let genericMessage = ZMGenericMessage.message(content: ZMText.text(with: text, linkPreviews: [linkPreview]), nonce: UUID.create(), expiresAfter: 20.0)
        
        // when
        let obfuscated =  genericMessage.obfuscatedMessage()
        
        // then
        guard let obfuscatedLinkPreview = obfuscated?.linkPreviews.first else { return XCTFail()}
        
        // then
        guard let obfuscatedTweet = obfuscatedLinkPreview.tweet else {return XCTFail()}
        XCTAssertNotEqual(obfuscatedTweet.author, "author")
        XCTAssertEqual(obfuscatedTweet.author.count, "author".count)

        XCTAssertNotEqual(obfuscatedTweet.username, "username")
        XCTAssertEqual(obfuscatedTweet.username.count, "username".count)
    }

    func testThatItObfuscatesImageAssetContent(){
        // given
        let image = ZMImageAsset(data: verySmallJPEGData(), format: .medium)!
        let genericMessage = ZMGenericMessage.message(content: image, nonce: UUID.create(), expiresAfter: 3.0)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(genericMessage.ephemeral.hasImage())
        XCTAssertEqual(genericMessage.imageAssetData?.mimeType, "image/jpeg")
        XCTAssertEqual(genericMessage.imageAssetData?.tag, "medium")
        XCTAssertEqual(genericMessage.imageAssetData?.originalWidth, 64)
        XCTAssertEqual(genericMessage.imageAssetData?.originalHeight, 64)
        XCTAssertNotEqual(genericMessage.imageAssetData?.size, 1)
        
        // when
        let obfuscated =  genericMessage.obfuscatedMessage()
        
        // then
        guard let obfuscatedImage = obfuscated?.image else { return XCTFail()}
        
        // then
        XCTAssertEqual(obfuscatedImage.mimeType, "image/jpeg")
        XCTAssertEqual(obfuscatedImage.tag, "medium")
        XCTAssertEqual(obfuscatedImage.originalWidth, 64)
        XCTAssertEqual(obfuscatedImage.originalHeight, 64)
        XCTAssertEqual(obfuscatedImage.size, 1)
    }
    
    
    func testThatItObfuscatesAssetsImageContent(){
        // given
        let asset  = assetWithImage()
        let genericMessage = ZMGenericMessage.message(content: asset, nonce: UUID.create(), expiresAfter: 20.0)
        
        // when
        let obfuscated =  genericMessage.obfuscatedMessage()
        
        // then
        guard let obfuscatedAsset = obfuscated?.asset else { return XCTFail()}
        
        // then
        XCTAssertTrue(obfuscatedAsset.hasOriginal())
        XCTAssertEqual(obfuscatedAsset.original.size, 10)
        XCTAssertEqual(obfuscatedAsset.original.mimeType, "image")
        XCTAssertEqual(obfuscatedAsset.preview.size, 10)
        XCTAssertEqual(obfuscatedAsset.preview.mimeType, "video")
        XCTAssertEqual(obfuscatedAsset.preview.image.width, 30)
        XCTAssertEqual(obfuscatedAsset.preview.image.height, 40)
        XCTAssertEqual(obfuscatedAsset.preview.image.tag, "bar")
        XCTAssertFalse(obfuscatedAsset.preview.hasRemote())
    }
    
    func testThatItObfuscatesAssetsVideoContent() {
        // given
        let original = ZMAssetOriginal.original(withSize: 200, mimeType: "video", name: "foo", videoDurationInMillis: 500, videoDimensions: CGSize(width: 305, height: 200))
        
        let asset  = ZMAsset.asset(withOriginal: original, preview: nil)
        let genericMessage = ZMGenericMessage.message(content: asset, nonce: UUID.create(), expiresAfter: 20.0)
        
        // when
        let obfuscated =  genericMessage.obfuscatedMessage()
        
        // then
        guard let obfuscatedAsset = obfuscated?.asset else { return XCTFail()}
        
        // then
        XCTAssertTrue(obfuscatedAsset.hasOriginal())
        XCTAssertEqual(obfuscatedAsset.original.size, 10)
        XCTAssertEqual(obfuscatedAsset.original.mimeType, "video")
        XCTAssertNotEqual(obfuscatedAsset.original.name, "foo")

        XCTAssertTrue(obfuscatedAsset.original.hasVideo())
        XCTAssertFalse(obfuscatedAsset.original.video.hasWidth())
        XCTAssertFalse(obfuscatedAsset.original.video.hasHeight())
        XCTAssertFalse(obfuscatedAsset.original.video.hasDurationInMillis())
    }
    
    func checkThatItObfuscatesAudioMessages() {
        // given
        let original = ZMAssetOriginal.original(withSize: 200, mimeType: "audio", name: "foo", audioDurationInMillis: 300, normalizedLoudness: [2.9])
        let asset  = ZMAsset.asset(withOriginal: original, preview: nil)
        let genericMessage = ZMGenericMessage.message(content: asset, nonce: UUID.create(), expiresAfter: 20.0)
        
        // when
        let obfuscated =  genericMessage.obfuscatedMessage()
        
        // then
        guard let obfuscatedAsset = obfuscated?.asset else { return XCTFail()}
        
        XCTAssertTrue(obfuscatedAsset.hasOriginal())
        XCTAssertEqual(obfuscatedAsset.original.size, 10)
        XCTAssertEqual(obfuscatedAsset.original.mimeType, "audio")
        XCTAssertNotEqual(obfuscatedAsset.original.name, "foo")
        
        XCTAssertTrue(obfuscatedAsset.original.hasAudio())
        XCTAssertFalse(obfuscatedAsset.original.audio.hasDurationInMillis())
        XCTAssertFalse(obfuscatedAsset.original.audio.hasNormalizedLoudness())
    }
    
    func testThatItObfuscatesLocationMessages() {
        // given
        let location  = ZMLocation.location(withLatitude: 2.0, longitude: 3.0)
        let message = ZMGenericMessage.message(content: location, nonce: UUID.create(), expiresAfter: 20.0)
        
        // when
        let obfuscatedMessage = message.obfuscatedMessage()
        
        // then
        XCTAssertNotNil(obfuscatedMessage?.locationData)
        XCTAssertEqual(obfuscatedMessage?.location.longitude, 0.0)
        XCTAssertEqual(obfuscatedMessage?.location.latitude, 0.0)
    }
    
}
