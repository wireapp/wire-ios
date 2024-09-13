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

import XCTest
@testable import WireDataModel

class CacheAssetTests: BaseZMAssetClientMessageTests {
    override class func setUp() {
        super.setUp()
        DeveloperFlag.storage = UserDefaults(suiteName: UUID().uuidString)!
        var flag = DeveloperFlag.proteusViaCoreCrypto
        flag.isOn = false
    }

    override class func tearDown() {
        super.tearDown()
        DeveloperFlag.storage = UserDefaults.standard
    }

    // MARK: - Fixtures

    func fileAsset() -> WireDataModel.CacheAsset {
        let message = appendFileMessage(to: conversation)!
        return WireDataModel.CacheAsset(owner: message, type: .file, cache: uiMOC.zm_fileAssetCache)
    }

    func imageAsset() -> WireDataModel.CacheAsset {
        let message = appendImageMessage(to: conversation)
        return WireDataModel.CacheAsset(owner: message, type: .image, cache: uiMOC.zm_fileAssetCache)
    }

    func gifAsset() -> WireDataModel.CacheAsset {
        let message = appendImageMessage(to: conversation, imageData: data(forResource: "animated", extension: "gif"))
        return WireDataModel.CacheAsset(owner: message, type: .image, cache: uiMOC.zm_fileAssetCache)
    }

    func thumbnailAsset() -> WireDataModel.CacheAsset {
        let message = appendFileMessage(to: conversation)!
        let asset = WireDataModel.CacheAsset(owner: message, type: .thumbnail, cache: uiMOC.zm_fileAssetCache)

        // thumbnail
        uiMOC.zm_fileAssetCache.storeOriginalImage(data: verySmallJPEGData(), for: message)

        return asset
    }

    // MARK: - Retrieving original data

    func testThatOriginalDataCanBeRetrievedForFileMessage() {
        // given
        let sut = fileAsset()

        // then
        XCTAssertNotNil(sut.original)
    }

    func testThatOriginalDataCanBeRetrievedForImageMessage() {
        // given
        let sut = imageAsset()

        // then
        XCTAssertNotNil(sut.original)
    }

    func testThatOriginalDataCanBeRetrievedForVideoThumbnail() {
        // given
        let sut = thumbnailAsset()

        // then
        XCTAssertNotNil(sut.original)
    }

    // MARK: - Image processing

    func testThatNeedsProcessingIsNeededForGIFs() {
        // given
        let gifAsset = gifAsset()

        // then
        XCTAssert(gifAsset.needsPreprocessing)
    }

    func testThatNeedsProcessingIsOnlyNeededForImageTypes() {
        // given
        let fileAsset = fileAsset()
        let imageAsset = imageAsset()
        let thumbnailAsset = thumbnailAsset()

        // then
        XCTAssertFalse(fileAsset.needsPreprocessing)
        XCTAssertTrue(imageAsset.needsPreprocessing)
        XCTAssertTrue(thumbnailAsset.needsPreprocessing)
    }

    func testThatUpdateWithPreprocessedDataStoresThePreprocessedData() {
        // given
        let sut = imageAsset()

        // when
        sut.updateWithPreprocessedData(
            verySmallJPEGData(),
            imageProperties: ZMIImageProperties(
                size: CGSize(width: 100, height: 100),
                length: 123,
                mimeType: "image/jpeg"
            )
        )

        // then
        XCTAssertTrue(sut.hasPreprocessed)
        XCTAssertNotNil(sut.preprocessed)
    }

    // MARK: - Encrypting

    func testThatEncryptStoresTheEncryptedFile() {
        // given
        let sut = fileAsset()

        // when
        sut.encrypt()

        // then
        XCTAssertTrue(sut.hasEncrypted)
        XCTAssertNotNil(sut.encrypted)
    }

    func testThatEncryptStoresTheEncryptedImage() {
        // given
        let sut = imageAsset()
        sut.updateWithPreprocessedData(
            verySmallJPEGData(),
            imageProperties: ZMIImageProperties(
                size: CGSize(width: 100, height: 100),
                length: 123,
                mimeType: "image/jpeg"
            )
        )

        // when
        sut.encrypt()

        // then
        XCTAssertTrue(sut.hasEncrypted)
        XCTAssertNotNil(sut.encrypted)
    }

    func testThatEncryptStoresTheEncryptedGIF() {
        // given
        let sut = gifAsset()

        sut.updateWithPreprocessedData(
            data(forResource: "animated", extension: "gif"),
            imageProperties: ZMIImageProperties(
                size: CGSize(width: 640, height: 400),
                length: 185_798,
                mimeType: "image/gif"
            )
        )

        // when
        sut.encrypt()

        // then
        XCTAssertTrue(sut.hasEncrypted)
        XCTAssertNotNil(sut.encrypted)
    }

    func testThatEncryptFailsWhenTheImageHasNotBeenPreprocessed() {
        // given
        let sut = imageAsset()

        // when
        sut.encrypt()

        // then
        XCTAssertFalse(sut.hasEncrypted)
        XCTAssertNil(sut.encrypted)
    }

    func testThatEncryptStoresTheEncryptedThumbnail() {
        // given
        let sut = thumbnailAsset()
        sut.updateWithPreprocessedData(
            verySmallJPEGData(),
            imageProperties: ZMIImageProperties(
                size: CGSize(width: 100, height: 100),
                length: 123,
                mimeType: "image/jpeg"
            )
        )

        // when
        sut.encrypt()

        // then
        XCTAssertTrue(sut.hasEncrypted)
        XCTAssertNotNil(sut.encrypted)
    }

    // MARK: - Uploading

    func testUpdateAssetIdForFile() {
        // given
        let sut = fileAsset()
        sut.encrypt()

        // when
        sut.updateWithAssetId("asset-123", token: "token-123", domain: UUID().uuidString)

        // then
        XCTAssertTrue(sut.isUploaded)
    }

    func testUpdateAssetIdForImage() {
        // given
        let sut = imageAsset()
        sut.updateWithPreprocessedData(
            verySmallJPEGData(),
            imageProperties: ZMIImageProperties(
                size: CGSize(width: 100, height: 100),
                length: 123,
                mimeType: "image/jpeg"
            )
        )
        sut.encrypt()

        // when
        sut.updateWithAssetId("asset-123", token: "token-123", domain: UUID().uuidString)

        // then
        XCTAssertTrue(sut.isUploaded)
        XCTAssertNotNil(sut.encrypted)
        XCTAssertFalse(sut.hasOriginal)
        XCTAssertFalse(sut.hasPreprocessed)
    }

    func testUpdateAssetIdForThumbnail() {
        // given
        let sut = thumbnailAsset()
        sut.updateWithPreprocessedData(
            verySmallJPEGData(),
            imageProperties: ZMIImageProperties(
                size: CGSize(width: 100, height: 100),
                length: 123,
                mimeType: "image/jpeg"
            )
        )
        sut.encrypt()

        // when
        sut.updateWithAssetId("asset-123", token: "token-123", domain: UUID().uuidString)

        // then
        XCTAssertTrue(sut.isUploaded)
        XCTAssertNotNil(sut.encrypted)
        XCTAssertFalse(sut.hasOriginal)
        XCTAssertFalse(sut.hasPreprocessed)
    }
}
