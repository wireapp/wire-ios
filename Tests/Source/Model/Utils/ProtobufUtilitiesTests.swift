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

class ProtobufUtilitiesTests: XCTestCase {
    
    func testThatItSetsAndReadsTheLoudness() {
        
        // given
        let loudness : [Float] = [0.8, 0.3, 1.0, 0.0, 0.001]
        let sut = ZMAssetOriginal.original(withSize: 200, mimeType: "audio/m4a", name: "foo.m4a", audioDurationInMillis: 1000, normalizedLoudness: loudness)

        // when
        guard let extractedLoudness = sut.audio.normalizedLoudness else {return XCTFail()}
        
        // then
        XCTAssertTrue(sut.audio.hasNormalizedLoudness())
        XCTAssertEqual(extractedLoudness.count, loudness.count)
        XCTAssertEqual(loudness.map { Float(UInt8(roundf($0*255)))/255.0 } , sut.normalizedLoudnessLevels)
    }
    
    func testThatItDoesNotReturnTheLoudnessIfEmpty() {
        
        // given
        let sut = ZMAssetOriginal.original(withSize: 234, mimeType: "foo/bar", name: "boo.bar")
        
        // then
        XCTAssertEqual(sut.normalizedLoudnessLevels, [])
    }
    
    func testThatItCreatesALinkPreviewWithTheDeprecatedArticleInside() {
        // given
        let (title, summary, url, permanentURL) = ("title", "summary", "www.example.com/original", "www.example.com/permanent")
        let image = ZMAsset.asset(withUploadedOTRKey: Data.secureRandomData(ofLength: 16), sha256: Data.secureRandomData(ofLength: 16))

        let preview = ZMLinkPreview.linkPreview(
            withOriginalURL: url,
            permanentURL: permanentURL,
            offset: 42,
            title: title,
            summary: summary,
            imageAsset: image
        )
        
        // then
        XCTAssertEqual(preview.urlOffset, 42)
        XCTAssertEqual(preview.url, url)
        
        XCTAssertEqual(preview.title, title)
        XCTAssertEqual(preview.article.title, title)
        XCTAssertEqual(preview.summary, summary)
        XCTAssertEqual(preview.article.summary, summary)
        
        XCTAssertEqual(preview.image, image)
        XCTAssertEqual(preview.article.image, image)
    }
    
    func testThatItUpdatesTheLinkPreviewWithOTRKeyAndSha() {
        // given
        let preview = createLinkPreview()
        XCTAssertFalse(preview.article.image.hasUploaded())
        
        // when
        let (otrKey, sha256) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let metadata: ZMAssetImageMetaData = .imageMetaData(withWidth: 42, height: 12)
        let original: ZMAssetOriginal = .original(withSize: 256, mimeType: "image/jpeg", name: nil, imageMetaData: metadata)
        let updated = preview.update(withOtrKey: otrKey, sha256: sha256, original: original)
        
        // then
        [updated.article.image, updated.image].forEach { asset in
            guard let asset = asset else {
                XCTFail()
                return
            }
            XCTAssertTrue(asset.hasUploaded())
            XCTAssertEqual(asset.uploaded.otrKey, otrKey)
            XCTAssertEqual(asset.uploaded.sha256, sha256)
            XCTAssertEqual(asset.original.size, 256)
            XCTAssertEqual(asset.original.mimeType, "image/jpeg")
            XCTAssertEqual(asset.original.image.height, 12)
            XCTAssertEqual(asset.original.image.width, 42)
            XCTAssertFalse(asset.original.hasName())
        }
    }
    
    func testThatItUpdatesTheLinkPreviewWithAssetIDAndToken() {
        // given
        let preview = createLinkPreview().update(withOtrKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key())
        XCTAssertTrue(preview.article.image.hasUploaded())
        XCTAssertFalse(preview.article.image.uploaded.hasAssetId())
        
        // when
        let (assetKey, token) = ("key", "token")
        let updated = preview.update(withAssetKey: assetKey, assetToken: token)
        
        // then
        [updated.article.image, updated.image].forEach { asset in
            guard let asset = asset else {
                XCTFail()
                return
            }
            XCTAssertTrue(asset.uploaded.hasAssetId())
            XCTAssertEqual(asset.uploaded.assetId, assetKey)
            XCTAssertEqual(asset.uploaded.assetToken, token)
        }
    }

    func testThatItUpdatesRemoteAssetDataWIthAssetIdAndAssetToken() {
        // given 
        let (otrKey, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let (assetId, token) = ("id", "token")
        let sut = ZMAssetRemoteData.remoteData(withOTRKey: otrKey, sha256: sha)

        // when
        let updated = sut.updated(withId: assetId, token: token)

        // then
        XCTAssertEqual(updated.assetId, assetId)
        XCTAssertEqual(updated.assetToken, token)
        XCTAssertEqual(updated.otrKey, otrKey)
        XCTAssertEqual(updated.sha256, sha)
    }

    func testThatItUpdatesAGenericMessageWithAssetUploadedWithAssetIdAndToken() {
        // given
        let (otrKey, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let (assetId, token) = ("id", "token")
        let asset = ZMAsset.asset(withUploadedOTRKey: otrKey, sha256: sha)
        let sut = ZMGenericMessage.message(content: asset, nonce: UUID.create())

        // when
        guard let updated = sut.updatedUploaded(withAssetId: assetId, token: token) else { return XCTFail() }

        // then
        XCTAssertFalse(updated.hasEphemeral())
        XCTAssert(updated.hasAsset())
        XCTAssertEqual(updated.asset.uploaded.assetId, assetId)
        XCTAssertEqual(updated.asset.uploaded.assetToken, token)
        XCTAssertEqual(updated.asset.uploaded.otrKey, otrKey)
        XCTAssertEqual(updated.asset.uploaded.sha256, sha)
    }

    func testThatItUpdatesAGenericMessageWithAssetUploadedWithAssetIdAndToken_Ephemeral() {
        // given
        let (otrKey, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let (assetId, token) = ("id", "token")
        let asset = ZMAsset.asset(withUploadedOTRKey: otrKey, sha256: sha)
        let sut = ZMGenericMessage.message(content: asset, nonce: UUID.create(), expiresAfter: 15)

        // when
        guard let updated = sut.updatedUploaded(withAssetId: assetId, token: token) else { return XCTFail() }

        // then
        XCTAssert(updated.hasEphemeral())
        XCTAssertFalse(updated.hasAsset())
        XCTAssertEqual(updated.ephemeral.asset.uploaded.assetId, assetId)
        XCTAssertEqual(updated.ephemeral.asset.uploaded.assetToken, token)
        XCTAssertEqual(updated.ephemeral.asset.uploaded.otrKey, otrKey)
        XCTAssertEqual(updated.ephemeral.asset.uploaded.sha256, sha)
    }

    func testThatItUpdatesAGenericMessageWithAssetPreviewWithAssetIdAndToken() {
        // given
        let (otr, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let (assetId, token) = ("id", "token")
        let previewAsset = ZMAssetPreview.preview(
            withSize: 128,
            mimeType: "image/jpg",
            remoteData: .remoteData(withOTRKey: otr, sha256: sha, assetId: nil, assetToken: nil),
            imageMetadata: .imageMetaData(withWidth: 123, height: 420)
        )

        let sut = ZMGenericMessage.message(
            content: ZMAsset.asset(withOriginal: nil, preview: previewAsset),
            nonce: UUID.create()
        )

        // when
        guard let updated = sut.updatedPreview(withAssetId: assetId, token: token) else { return XCTFail() }

        // then
        XCTAssertFalse(updated.hasEphemeral())
        XCTAssert(updated.hasAsset())
        XCTAssertEqual(updated.asset.preview.remote.assetId, assetId)
        XCTAssertEqual(updated.asset.preview.remote.assetToken, token)
        XCTAssertEqual(updated.asset.preview.remote.otrKey, otr)
        XCTAssertEqual(updated.asset.preview.remote.sha256, sha)
    }

    func testThatItUpdatesAGenericMessageWithAssetPreviewWithAssetIdAndToken_Ephemeral() {
        // given
        let (otr, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let (assetId, token) = ("id", "token")
        let previewAsset = ZMAssetPreview.preview(
            withSize: 128,
            mimeType: "image/jpg",
            remoteData: .remoteData(withOTRKey: otr, sha256: sha, assetId: nil, assetToken: nil),
            imageMetadata: .imageMetaData(withWidth: 123, height: 420)
        )

        let sut = ZMGenericMessage.message(
            content: ZMAsset.asset(withOriginal: nil, preview: previewAsset),
            nonce: UUID.create(),
            expiresAfter: 15
        )

        // when
        guard let updated = sut.updatedPreview(withAssetId: assetId, token: token) else { return XCTFail() }

        // then
        XCTAssertTrue(updated.hasEphemeral())
        XCTAssert(updated.ephemeral.hasAsset())
        XCTAssertEqual(updated.ephemeral.asset.preview.remote.assetId, assetId)
        XCTAssertEqual(updated.ephemeral.asset.preview.remote.assetToken, token)
        XCTAssertEqual(updated.ephemeral.asset.preview.remote.otrKey, otr)
        XCTAssertEqual(updated.ephemeral.asset.preview.remote.sha256, sha)
    }
    
    // MARK:- Helper
    
    func createLinkPreview() -> ZMLinkPreview {
        return .linkPreview(
            withOriginalURL: "www.example.com/original",
            permanentURL: "www.example.com/permanent",
            offset: 42,
            title: "Title",
            summary: name,
            imageAsset: nil
        )
    }
}
