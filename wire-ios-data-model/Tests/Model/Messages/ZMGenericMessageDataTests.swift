//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import GenericMessageProtocol
import XCTest

@testable import WireDataModel

class ZMGenericMessageDataTests: ModelObjectsTests {

    // MARK: - Set Up

    private var earMessageEncryptionService: EARMessageEncryptionService!
    private var earStorage: EARStorage!

    override func setUp() {
        super.setUp()

        earStorage = EARStorage(userID: UUID(), sharedUserDefaults: .temporary())
        earStorage.enableEAR(false)

        let service = EARMessageEncryptionService(earStorage: earStorage)
        earMessageEncryptionService = service

        createSelfClient(onMOC: uiMOC)
        uiMOC.encryptMessagesAtRest = false
        uiMOC.earMessageEncryptionService = service
    }

    override func tearDown() {
        earStorage = nil
        earMessageEncryptionService = nil

        super.tearDown()
    }

    // MARK: - Positive Tests

    func test_ItDoesNotEncryptProtobufData_IfEncryptionAtRest_IsDisabled() throws {
        // Given
        let sut = ZMGenericMessageData.insertNewObject(in: uiMOC)
        let genericMessage = createGenericMessage(text: "Hello, world")

        XCTAssertFalse(earStorage.earEnabled())
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)

        // When
        try sut.setGenericMessage(genericMessage)

        // Then
        XCTAssertFalse(sut.isEncrypted)
        XCTAssertNil(sut.nonce)
        XCTAssertEqual(sut.underlyingMessage, genericMessage)
    }

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func test_ItEncryptsAndDecryptsProtobufData_IfEncryptionAtRest_IsEnabled() throws {
        // Given
        let sut = ZMGenericMessageData.insertNewObject(in: uiMOC)
        let genericMessage = createGenericMessage(text: "Hello, world")

        setEAREnabled(true)
        earMessageEncryptionService.setDatabaseKey(validDatabaseKey)

        // When
        try sut.setGenericMessage(genericMessage)

        // Then
        XCTAssertTrue(sut.isEncrypted)
        XCTAssertNotNil(sut.nonce)
        XCTAssertEqual(sut.underlyingMessage, genericMessage)
    }

    // MARK: - Negative Tests

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func test_ItDoesNotStoreData_IfDatabaseKeyIsMissing_WhenEncrypting() throws {
        // Given
        let sut = ZMGenericMessageData.insertNewObject(in: uiMOC)
        let databaseKey = validDatabaseKey
        let oldGenericMessage = try createAndStoreEncryptedData(
            sut: sut,
            text: "Hello, world",
            databaseKey: databaseKey
        )

        // When
        let newGenericMessage = createGenericMessage(text: "Goodbye!")

        earMessageEncryptionService.setDatabaseKey(nil)

        XCTAssertThrowsError(try sut.setGenericMessage(newGenericMessage))

        // Then
        earMessageEncryptionService.setDatabaseKey(databaseKey)

        XCTAssertEqual(sut.underlyingMessage, oldGenericMessage)
    }

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func test_ItDoesNotReturnData_IfDatabaseKeyIsMissing_WhenDecrypting() throws {
        // Given
        let sut = ZMGenericMessageData.insertNewObject(in: uiMOC)
        try createAndStoreEncryptedData(sut: sut, text: "Hello, world")

        // When
        earMessageEncryptionService.setDatabaseKey(nil)

        // Then
        XCTAssertNil(sut.underlyingMessage)
    }

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func test_ItDoesNotStoreData_IfEncryptionFails_WhenEncrypting() throws {
        // Given
        let sut = ZMGenericMessageData.insertNewObject(in: uiMOC)
        let databaseKey = validDatabaseKey
        let oldGenericMessage = try createAndStoreEncryptedData(
            sut: sut,
            text: "Hello, world",
            databaseKey: databaseKey
        )

        // When
        let newGenericMessage = createGenericMessage(text: "Goodbye!")

        earMessageEncryptionService.setDatabaseKey(malformedDatabaseKey)

        XCTAssertThrowsError(try sut.setGenericMessage(newGenericMessage))

        // Then
        earMessageEncryptionService.setDatabaseKey(databaseKey)

        XCTAssertEqual(sut.underlyingMessage, oldGenericMessage)
    }

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func test_ItDoesNotReturnData_IfDecryptionFails_WhenDecrypting() throws {
        // Given
        let sut = ZMGenericMessageData.insertNewObject(in: uiMOC)
        try createAndStoreEncryptedData(sut: sut, text: "Hello, world")

        // When
        earMessageEncryptionService.setDatabaseKey(malformedDatabaseKey)

        // Then
        XCTAssertNil(sut.underlyingMessage)
    }

    // MARK: - Helpers

    private func setEAREnabled(_ enabled: Bool) {
        uiMOC.encryptMessagesAtRest = enabled
        earStorage.enableEAR(enabled)
    }

    private func createGenericMessage(text: String) -> GenericMessage {
        GenericMessage(content: Text(content: text))
    }

    @discardableResult
    private func createAndStoreEncryptedData(
        sut: ZMGenericMessageData,
        text: String,
        databaseKey: VolatileData? = nil
    ) throws -> GenericMessage {
        let genericMessage = createGenericMessage(text: text)

        setEAREnabled(true)
        earMessageEncryptionService.setDatabaseKey(databaseKey ?? validDatabaseKey)

        try sut.setGenericMessage(genericMessage)

        XCTAssertEqual(sut.underlyingMessage, genericMessage)

        return genericMessage
    }

}
