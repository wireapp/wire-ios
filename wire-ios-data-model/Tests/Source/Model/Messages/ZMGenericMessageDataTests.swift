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

class ZMGenericMessageDataTests: ModelObjectsTests {
    // MARK: Internal

    // MARK: - Set Up

    override func setUp() {
        super.setUp()

        createSelfClient(onMOC: uiMOC)
        uiMOC.encryptMessagesAtRest = false
        uiMOC.databaseKey = nil
    }

    // MARK: - Positive Tests

    func test_ItDoesNotEncryptProtobufData_IfEncryptionAtRest_IsDisabled() throws {
        // Given
        let sut = ZMGenericMessageData.insertNewObject(in: uiMOC)
        let genericMessage = createGenericMessage(text: "Hello, world")

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

        uiMOC.encryptMessagesAtRest = true
        uiMOC.databaseKey = validDatabaseKey

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
        let oldGenericMessage = try createAndStoreEncryptedData(sut: sut, text: "Hello, world")
        let databaseKey = uiMOC.databaseKey

        // When
        let newGenericMessage = createGenericMessage(text: "Goodbye!")

        uiMOC.databaseKey = nil

        XCTAssertThrowsError(try sut.setGenericMessage(newGenericMessage))

        // Then
        uiMOC.databaseKey = databaseKey

        XCTAssertEqual(sut.underlyingMessage, oldGenericMessage)
    }

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func test_ItDoesNotReturnData_IfDatabaseKeyIsMissing_WhenDecrypting() throws {
        // Given
        let sut = ZMGenericMessageData.insertNewObject(in: uiMOC)
        try createAndStoreEncryptedData(sut: sut, text: "Hello, world")

        // When
        uiMOC.databaseKey = nil

        // Then
        XCTAssertNil(sut.underlyingMessage)
    }

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func test_ItDoesNotStoreData_IfEncryptionFails_WhenEncrypting() throws {
        // Given
        let sut = ZMGenericMessageData.insertNewObject(in: uiMOC)
        let oldGenericMessage = try createAndStoreEncryptedData(sut: sut, text: "Hello, world")
        let databaseKey = uiMOC.databaseKey

        // When
        let newGenericMessage = createGenericMessage(text: "Goodbye!")

        uiMOC.databaseKey = malformedDatabaseKey

        XCTAssertThrowsError(try sut.setGenericMessage(newGenericMessage))

        // Then
        uiMOC.databaseKey = databaseKey

        XCTAssertEqual(sut.underlyingMessage, oldGenericMessage)
    }

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func test_ItDoesNotReturnData_IfDecryptionFails_WhenDecrypting() throws {
        // Given
        let sut = ZMGenericMessageData.insertNewObject(in: uiMOC)
        try createAndStoreEncryptedData(sut: sut, text: "Hello, world")

        // When
        uiMOC.databaseKey = malformedDatabaseKey

        // Then
        XCTAssertNil(sut.underlyingMessage)
    }

    // MARK: Private

    // MARK: - Helpers

    private func createGenericMessage(text: String) -> GenericMessage {
        GenericMessage(content: Text(content: text))
    }

    @discardableResult
    private func createAndStoreEncryptedData(sut: ZMGenericMessageData, text: String) throws -> GenericMessage {
        let genericMessage = createGenericMessage(text: text)

        uiMOC.encryptMessagesAtRest = true
        uiMOC.databaseKey = validDatabaseKey

        try sut.setGenericMessage(genericMessage)

        XCTAssertEqual(sut.underlyingMessage, genericMessage)

        return genericMessage
    }
}
