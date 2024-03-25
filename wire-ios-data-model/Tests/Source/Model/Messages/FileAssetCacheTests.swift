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
import WireDataModelSupport
@testable import WireDataModel

class FileAssetCacheTests: XCTestCase {

    var sut: FileAssetCache!
    var location: URL!
    var coreDataStack: CoreDataStack!

    var coreDataStackHelper: CoreDataStackHelper!
    var modelHelper: ModelHelper!

    var context: NSManagedObjectContext {
        return coreDataStack.viewContext
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
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
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

    private func createMessageForCaching() -> ZMConversationMessage {
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.remoteIdentifier = UUID()
        return try! conversation.appendText(content: "123")
    }

    private func testData() -> Data {
        return Data.secureRandomData(ofLength: 2000)
    }

    // MARK: - Storing and retrieving image assets

    func testThatStoringAndRetrievingAssetsWithDifferentOptionsRetrievesTheRightData() throws {
        // given
        let message1 = createMessageForCaching()
        let message2 = createMessageForCaching()
        let data1_plain = "data1_plain".data(using: String.Encoding.utf8)!
        let data2_plain = "data2_plain".data(using: String.Encoding.utf8)!
        let data1_enc = "data1_enc".data(using: String.Encoding.utf8)!
        let data2_enc = "data2_enc".data(using: String.Encoding.utf8)!

        sut.storeAssetData(message1, encrypted: true, data: data1_enc)
        sut.storeAssetData(message2, encrypted: true, data: data2_enc)
        sut.storeAssetData(message1, encrypted: false, data: data1_plain)
        sut.storeAssetData(message2, encrypted: false, data: data2_plain)

        // then
        XCTAssertEqual(sut.assetData(message1, encrypted: false), data1_plain)
        XCTAssertEqual(sut.assetData(message2, encrypted: false), data2_plain)
        XCTAssertEqual(sut.assetData(message1, encrypted: true), data1_enc)
        XCTAssertEqual(sut.assetData(message2, encrypted: true), data2_enc)

        XCTAssertTrue(sut.hasDataOnDisk(message1, encrypted: false))
        XCTAssertTrue(sut.hasDataOnDisk(message2, encrypted: false))
        XCTAssertTrue(sut.hasDataOnDisk(message1, encrypted: true))
        XCTAssertTrue(sut.hasDataOnDisk(message2, encrypted: true))
    }

    func testThatCreationDateIsLinkedToMessageServerTimestamp() throws {
        // given
        let message = createMessageForCaching() as! ZMClientMessage
        message.serverTimestamp = Date(timeIntervalSinceReferenceDate: 1000)

        // when
        sut.storeAssetData(message, encrypted: false, data: "data1_plain".data(using: String.Encoding.utf8)!)

        // then
        let url = try XCTUnwrap(sut.accessAssetURL(message))
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let creationDate = attributes[.creationDate] as? Date
        XCTAssertEqual(creationDate, message.serverTimestamp)
    }

    func testThatHasDataOnDisk() {

        // given
        let message = createMessageForCaching()
        sut.storeAssetData(message, encrypted: false, data: testData())

        // when
        let data = sut.hasDataOnDisk(message, encrypted: false)

        // then
        XCTAssertTrue(data)
    }

    func testThatHasNoDataOnDiskWithWrongEncryptionFlag() {

        // given
        let message = createMessageForCaching()
        sut.storeAssetData(message, encrypted: false, data: testData())

        // when
        let data = sut.hasDataOnDisk(message, encrypted: true)

        // then
        XCTAssertFalse(data)
    }

    func testThatRetrievingMissingAssetsUUIDReturnsNil() {

        // given
        let message1 = createMessageForCaching()
        let message2 = createMessageForCaching()
        sut.storeAssetData(message1, encrypted: false, data: testData())

        // when
        let data = sut.assetData(message2, encrypted: false)

        // then
        XCTAssertNil(data)
    }

    func testThatHasNoDataOnDiskWithWrongUUID() {

        // given
        let message1 = createMessageForCaching()
        let message2 = createMessageForCaching()
        sut.storeAssetData(message1, encrypted: false, data: testData())

        // when
        let data = sut.hasDataOnDisk(message2, encrypted: false)

        // then
        XCTAssertFalse(data)
    }

    func testThatAssetsAreLoadedAcrossInstances() throws {
        // given
        let message = createMessageForCaching()
        let data = testData()
        sut.storeAssetData(message, encrypted: false, data: data)

        // when
        let newSUT = FileAssetCache(location: location)
        let extractedData = newSUT.assetData(message, encrypted: false)

        // then
        XCTAssertEqual(extractedData, data)
    }

    func testThatItDeletesAnExistingAssetData() {

        // given
        let message = createMessageForCaching()
        let data = testData()
        sut.storeAssetData(message, encrypted: false, data: data)

        // when
        sut.deleteAssetData(message, encrypted: false)
        let extractedData = sut.assetData(message, encrypted: false)

        // then
        XCTAssertNil(extractedData)
    }

    func testThatItDeletesTheRightAssetData() {

        // given
        let message1 = createMessageForCaching()
        let message2 = createMessageForCaching()
        let data = testData()
        sut.storeAssetData(message1, encrypted: true, data: data)
        sut.storeAssetData(message1, encrypted: false, data: data)

        // when
        sut.deleteAssetData(message1, encrypted: false) // this one exists
        sut.deleteAssetData(message2, encrypted: false) // this one doesn't exist
        let expectedNilData = sut.assetData(message1, encrypted: false)
        let expectedNotNilData = sut.assetData(message1, encrypted: true)

        // then
        XCTAssertNil(expectedNilData)
        AssertOptionalEqual(expectedNotNilData, expression2: data)
    }

    func testThatItDeletesAssets_WhenAssetIsOlderThanGivenDate() {
        let message = createMessageForCaching()
        let data = testData()
        sut.storeAssetData(message, encrypted: false, data: data)

        // when
        sut.deleteAssetsOlderThan(Date())

        // then
        XCTAssertNil(sut.assetData(message, encrypted: false))
    }

    func testThatItKeepsAssets_WhenAssetIsNewerThanGivenDate() {
        let message = createMessageForCaching()
        let data = testData()
        sut.storeAssetData(message, encrypted: false, data: data)

        // when
        sut.deleteAssetsOlderThan(Date.distantPast)

        // then
        XCTAssertNotNil(sut.assetData(message, encrypted: false))
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
        XCTAssertNil(sut.assetData(message, encrypted: true))
    }

    func testThatItCreatesTheEncryptedFileAndDeletesThePlainTextWithSHA256() {

        // given
        let message = createMessageForCaching()
        let plainData = Data.secureRandomData(ofLength: 500)

        sut.storeAssetData(message, encrypted: false, data: plainData)

        // when
        _ = sut.encryptFileAndComputeSHA256Digest(message)

        // then
        XCTAssertNotNil(sut.assetData(message, encrypted: true))
        XCTAssertNil(sut.assetData(message, encrypted: false))
    }

    func testThatItReturnsCorrectEncryptionResultWithSHA256() {
        // given
        let message = createMessageForCaching()
        let plainData = Data.secureRandomData(ofLength: 500)

        sut.storeAssetData(message, encrypted: false, data: plainData)

        // when
        let result = sut.encryptFileAndComputeSHA256Digest(message)

        // then
        let encryptedData = sut.assetData(message, encrypted: true)
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
        XCTAssertNil(sut.assetData(message, encrypted: true))
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
        if let assetURL = assetURL {
            let data = try? Data(contentsOf: assetURL)
            XCTAssertNil(data)
        }
    }

    // MARK: - FileAssetCache

    func testThatHasDataOnDiskForTeam() {
        // given
        let syncContext = coreDataStack.syncContext
        syncContext.performGroupedBlockAndWait {
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
        syncContext.performGroupedBlockAndWait {
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

}

extension FileManager {

    func removeItemIfExists(at url: URL) throws {
        guard fileExists(atPath: url.path) else { return }
        try removeItem(atPath: url.path)
    }

}
