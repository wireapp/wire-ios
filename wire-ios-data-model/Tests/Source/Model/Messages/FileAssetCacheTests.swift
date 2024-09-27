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

import WireDataModelSupport
import WireTesting
import XCTest
@testable import WireDataModel

// MARK: - FileAssetCacheTests

class FileAssetCacheTests: XCTestCase {
    // MARK: Internal

    var sut: FileAssetCache!
    var location: URL!
    var coreDataStack: CoreDataStack!

    var coreDataStackHelper: CoreDataStackHelper!
    var modelHelper: ModelHelper!

    var context: NSManagedObjectContext {
        coreDataStack.viewContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()

        coreDataStack = try await coreDataStackHelper.createStack()

        await context.perform {
            self.modelHelper.createSelfUser(in: self.context)
            self.modelHelper.createSelfClient(in: self.context)
        }

        location = try XCTUnwrap(
            FileManager.default.randomCacheURL
        )

        try FileManager.default.removeItemIfExists(at: location!)
        sut = FileAssetCache(location: location!)
    }

    override func tearDown() async throws {
        try FileManager.default.removeItemIfExists(at: location!)
        try coreDataStackHelper.cleanupDirectory()
        sut = nil
        location = nil
        coreDataStack = nil
        coreDataStackHelper = nil
        modelHelper = nil
        try await super.tearDown()
    }

    // MARK: - Storing and retrieving image assets

    func testThatStoringAndRetrievingAssetsWithDifferentOptionsRetrievesTheRightData() throws {
        // given
        let message1 = createMessageForCaching()
        let message2 = createMessageForCaching()
        let data1_plain = Data("data1_plain".utf8)
        let data2_plain = Data("data2_plain".utf8)
        let data1_enc = Data("data1_enc".utf8)
        let data2_enc = Data("data2_enc".utf8)

        sut.storeEncryptedFile(data: data1_enc, for: message1)
        sut.storeEncryptedFile(data: data2_enc, for: message2)
        sut.storeOriginalFile(data: data1_plain, for: message1)
        sut.storeOriginalFile(data: data2_plain, for: message2)

        // then
        XCTAssertEqual(sut.originalFileData(for: message1), data1_plain)
        XCTAssertEqual(sut.originalFileData(for: message2), data2_plain)
        XCTAssertEqual(sut.encryptedFileData(for: message1), data1_enc)
        XCTAssertEqual(sut.encryptedFileData(for: message2), data2_enc)

        XCTAssertTrue(sut.hasOriginalFileData(for: message1))
        XCTAssertTrue(sut.hasOriginalFileData(for: message2))
        XCTAssertTrue(sut.hasEncryptedFileData(for: message1))
        XCTAssertTrue(sut.hasEncryptedFileData(for: message2))
    }

    func testThatCreationDateIsLinkedToMessageServerTimestamp() throws {
        // given
        let message = createMessageForCaching() as! ZMClientMessage
        message.serverTimestamp = Date(timeIntervalSinceReferenceDate: 1000)

        // when
        sut.storeOriginalFile(data: Data("data1_plain".utf8), for: message)

        // then
        let url = try XCTUnwrap(sut.accessAssetURL(message))
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let creationDate = attributes[.creationDate] as? Date
        XCTAssertEqual(creationDate, message.serverTimestamp)
    }

    func testThatHasDataOnDisk() {
        // given
        let message = createMessageForCaching()
        sut.storeOriginalFile(data: testData(), for: message)

        // when
        let data = sut.hasOriginalFileData(for: message)

        // then
        XCTAssertTrue(data)
    }

    func testThatHasNoDataOnDiskWithWrongEncryptionFlag() {
        // given
        let message = createMessageForCaching()
        sut.storeOriginalFile(data: testData(), for: message)

        // when
        let data = sut.hasEncryptedFileData(for: message)

        // then
        XCTAssertFalse(data)
    }

    func testThatRetrievingMissingAssetsUUIDReturnsNil() {
        // given
        let message1 = createMessageForCaching()
        let message2 = createMessageForCaching()
        sut.storeOriginalFile(data: testData(), for: message1)

        // when
        let data = sut.originalFileData(for: message2)

        // then
        XCTAssertNil(data)
    }

    func testThatHasNoDataOnDiskWithWrongUUID() {
        // given
        let message1 = createMessageForCaching()
        let message2 = createMessageForCaching()
        sut.storeOriginalFile(data: testData(), for: message1)

        // when
        let data = sut.hasOriginalFileData(for: message2)

        // then
        XCTAssertFalse(data)
    }

    func testThatAssetsAreLoadedAcrossInstances() throws {
        // given
        let message = createMessageForCaching()
        let data = testData()
        sut.storeOriginalFile(data: data, for: message)

        // when
        let newSUT = FileAssetCache(location: location)
        let extractedData = newSUT.originalFileData(for: message)

        // then
        XCTAssertEqual(extractedData, data)
    }

    func testThatItDeletesAnExistingAssetData() {
        // given
        let message = createMessageForCaching()
        let data = testData()
        sut.storeOriginalFile(data: data, for: message)

        // when
        sut.deleteOriginalFileData(for: message)
        let extractedData = sut.originalImageData(for: message)

        // then
        XCTAssertNil(extractedData)
    }

    func testThatItDeletesTheRightAssetData() {
        // given
        let message1 = createMessageForCaching()
        let message2 = createMessageForCaching()
        let data = testData()
        sut.storeEncryptedFile(data: data, for: message1)
        sut.storeOriginalFile(data: data, for: message1)

        // when
        sut.deleteOriginalFileData(for: message1) // this one exists
        sut.deleteOriginalFileData(for: message2) // this one doesn't exist
        let expectedNilData = sut.originalFileData(for: message1)
        let expectedNotNilData = sut.encryptedFileData(for: message1)

        // then
        XCTAssertNil(expectedNilData)
        AssertOptionalEqual(expectedNotNilData, expression2: data)
    }

    func testThatItDeletesAssets_WhenAssetIsOlderThanGivenDate() {
        let message = createMessageForCaching()
        let data = testData()
        sut.storeOriginalFile(data: data, for: message)

        // when
        sut.deleteAssetsOlderThan(Date())

        // then
        XCTAssertNil(sut.originalFileData(for: message))
    }

    func testThatItKeepsAssets_WhenAssetIsNewerThanGivenDate() {
        let message = createMessageForCaching()
        let data = testData()
        sut.storeOriginalFile(data: data, for: message)

        // when
        sut.deleteAssetsOlderThan(Date.distantPast)

        // then
        XCTAssertNotNil(sut.originalFileData(for: message))
    }

    func testThatItDoesNotDecryptAFileThatDoesNotExistSHA256() {
        // given
        let message = createMessageForCaching()
        XCTAssertFalse(sut.hasEncryptedMediumImageData(for: message))

        // when
        let result = sut.decryptedMediumImageData(
            for: message,
            encryptionKey: .randomEncryptionKey(),
            sha256Digest: .secureRandomData(
                length: 128
            )
        )

        // then
        XCTAssertNil(result)
        XCTAssertFalse(sut.hasEncryptedMediumImageData(for: message))
    }

    func testThatItDoesNotDecryptAFileIfSHA256IsEmpty() {
        // given
        let message = createMessageForCaching()
        sut.storeEncryptedMediumImage(data: testData(), for: message)
        XCTAssertTrue(sut.hasEncryptedMediumImageData(for: message))

        // when
        let result = sut.decryptedMediumImageData(
            for: message,
            encryptionKey: .randomEncryptionKey(),
            sha256Digest: Data()
        )

        // then
        XCTAssertNil(result)
        XCTAssertTrue(sut.hasEncryptedMediumImageData(for: message))
    }

    // @SF.Messages @TSFI.RESTfulAPI @S0.1 @S0.2 @S0.3
    func testThatItDoesNotDecryptAndDeletesAFileWithWrongSHA256() {
        // given
        let message = createMessageForCaching()
        sut.storeEncryptedMediumImage(data: testData(), for: message)
        XCTAssertTrue(sut.hasEncryptedMediumImageData(for: message))

        // when
        let result = sut.decryptedMediumImageData(
            for: message,
            encryptionKey: .randomEncryptionKey(),
            sha256Digest: .secureRandomData(
                length: 128
            )
        )

        // then
        XCTAssertNil(result)
        XCTAssertFalse(sut.hasEncryptedMediumImageData(for: message))
    }

    // @SF.Messages @TSFI.RESTfulAPI @S0.1 @S0.2 @S0.3
    func testThatItDoesDecryptAFileWithTheRightSHA256() throws {
        // given
        let message = createMessageForCaching()
        let plainTextData = Data.secureRandomData(ofLength: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = try plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        sut.storeEncryptedMediumImage(data: encryptedData, for: message)
        XCTAssertTrue(sut.hasEncryptedMediumImageData(for: message))

        // when
        let decryptedData = try XCTUnwrap(sut.decryptedMediumImageData(
            for: message,
            encryptionKey: key,
            sha256Digest: sha
        ))

        // then
        XCTAssertEqual(decryptedData, plainTextData)
    }

    // MARK: - File encryption

    func testThatReturnsNilWhenEncryptingAMissingFileWithSHA256() {
        // given
        let message = createMessageForCaching()

        // when
        let result = sut.encryptFileAndComputeSHA256Digest(message)

        // then
        AssertOptionalNil(result)
        XCTAssertNil(sut.encryptedFileData(for: message))
    }

    func testThatItCreatesTheEncryptedFileAndDeletesThePlainTextWithSHA256() {
        // given
        let message = createMessageForCaching()
        let plainData = Data.secureRandomData(ofLength: 500)

        sut.storeOriginalFile(data: plainData, for: message)

        // when
        _ = sut.encryptFileAndComputeSHA256Digest(message)

        // then
        XCTAssertNotNil(sut.encryptedFileData(for: message))
        XCTAssertNil(sut.originalFileData(for: message))
    }

    func testThatItReturnsCorrectEncryptionResultWithSHA256() {
        // given
        let message = createMessageForCaching()
        let plainData = Data.secureRandomData(ofLength: 500)

        sut.storeOriginalFile(data: plainData, for: message)

        // when
        let result = sut.encryptFileAndComputeSHA256Digest(message)

        // then
        let encryptedData = sut.encryptedFileData(for: message)
        AssertOptionalNotNil(result, "Result") { result in
            AssertOptionalNotNil(encryptedData, "Encrypted data") { encryptedData in
                let decodedData = encryptedData.zmDecryptPrefixedPlainTextIV(key: result.otrKey)
                XCTAssertEqual(decodedData, plainData)
                let sha = encryptedData.zmSHA256Digest()
                XCTAssertEqual(sha, result.sha256)
            }
        }
    }

    // MARK: - Image encryption

    func testThatReturnsNilWhenEncryptingAMissingImageWithSHA256() {
        // given
        let message = createMessageForCaching()

        // when
        let result = sut.encryptImageAndComputeSHA256Digest(message, format: .medium)

        // then
        AssertOptionalNil(result)
        XCTAssertNil(sut.encryptedFileData(for: message))
    }

    func testThatItCreatesTheEncryptedImageAndDeletesThePlainTextWithSHA256() {
        // given
        let message = createMessageForCaching()
        let plainData = Data.secureRandomData(ofLength: 500)
        sut.storeMediumImage(data: plainData, for: message)

        // when
        _ = sut.encryptImageAndComputeSHA256Digest(message, format: .medium)

        // then
        XCTAssertNotNil(sut.encryptedMediumImageData(for: message))
        XCTAssertNil(sut.mediumImageData(for: message))
    }

    func testThatItReturnsCorrectEncryptionImageResultWithSHA256() {
        // given
        let message = createMessageForCaching()
        let plainData = Data.secureRandomData(ofLength: 500)
        sut.storeMediumImage(data: plainData, for: message)

        // when
        let result = sut.encryptImageAndComputeSHA256Digest(message, format: .medium)

        // then
        let encryptedData = sut.encryptedMediumImageData(for: message)
        AssertOptionalNotNil(result, "Result") { result in
            AssertOptionalNotNil(encryptedData, "Encrypted data") { encryptedData in
                let decodedData = encryptedData.zmDecryptPrefixedPlainTextIV(key: result.otrKey)
                XCTAssertEqual(decodedData, plainData)
                let sha = encryptedData.zmSHA256Digest()
                XCTAssertEqual(sha, result.sha256)
            }
        }
    }

    // MARK: - File urls

    func testThatItStoresTheRequestDataAndReturnsTheFileURL() {
        let message = createMessageForCaching()
        let requestData = Data.secureRandomData(ofLength: 500)

        // when
        let assetURL = sut.storeTransportData(requestData, for: message)

        // then
        guard let url = assetURL else { return XCTFail() }
        guard let data = try? Data(contentsOf: url) else { return XCTFail() }
        XCTAssertTrue(requestData == data)
    }

    func testThatItDeletesTheRequestData() {
        let message = createMessageForCaching()
        let requestData = Data.secureRandomData(ofLength: 500)

        // when
        let assetURL = sut.storeTransportData(requestData, for: message)
        sut.deleteTransportData(for: message)

        // then
        XCTAssertNotNil(assetURL)
        if let assetURL {
            let data = try? Data(contentsOf: assetURL)
            XCTAssertNil(data)
        }
    }

    // MARK: - FileAssetCache

    func testThatHasDataOnDiskForTeam() {
        // given
        let syncContext = coreDataStack.syncContext
        syncContext.performGroupedAndWait {
            let team = Team.mockTeam(context: syncContext)
            team.pictureAssetId = "abc123"
            self.sut.storeImage(data: self.testData(), for: team)

            // when
            let hasData = self.sut.hasImageData(for: team)

            // then
            XCTAssertTrue(hasData)
        }
    }

    func testThatItDeletesAnExistingAssetDataForTeam() {
        let syncContext = coreDataStack.syncContext
        syncContext.performGroupedAndWait {
            // given
            let team = Team.mockTeam(context: syncContext)
            team.pictureAssetId = "abc123"
            self.sut.storeImage(data: self.testData(), for: team)
            XCTAssertTrue(self.sut.hasImageData(for: team))

            // when
            self.sut.deleteImageData(for: team)

            // then
            XCTAssertFalse(self.sut.hasImageData(for: team))
        }
    }

    // MARK: Private

    private func createMessageForCaching() -> ZMConversationMessage {
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.remoteIdentifier = UUID()
        return try! conversation.appendText(content: "123")
    }

    private func testData() -> Data {
        Data.secureRandomData(ofLength: 2000)
    }
}

extension FileManager {
    func removeItemIfExists(at url: URL) throws {
        guard fileExists(atPath: url.path) else { return }
        try removeItem(atPath: url.path)
    }
}
