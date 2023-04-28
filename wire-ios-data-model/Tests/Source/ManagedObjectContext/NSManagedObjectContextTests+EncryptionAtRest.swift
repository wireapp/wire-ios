//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import XCTest
@testable import WireDataModel

class NSManagedObjectContextTests_EncryptionAtRest: ZMBaseManagedObjectTest {

    private typealias MigrationError = NSManagedObjectContext.MigrationError

    override func setUp() {
        super.setUp()
        createSelfClient(onMOC: uiMOC)
    }

    private func fetchObjects<T: ZMManagedObject>() throws -> [T] {
        let request = NSFetchRequest<T>(entityName: T.entityName())
        request.returnsObjectsAsFaults = false
        return try request.execute()
    }

    // MARK: - Negative Tests

    // MAYBE THIS IS NO LONGER NEEDED: WE PASS THE KEY ONWARDS.

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func testItThrowsAnError_WhenDatabaseKeyIsMissing_WhenEarIsEnabled() throws {
        // Given
        uiMOC.encryptionKeys = nil

        try uiMOC.performGroupedAndWait { moc in
            // When
            XCTAssertThrowsError(try moc.enableEncryptionAtRest(encryptionKeys: try moc.getEncryptionKeys())) { error in
                // Then
                guard case MigrationError.missingDatabaseKey = error else {
                    return XCTFail("Unexpected error thrown: \(error.localizedDescription)")
                }
            }

            XCTAssertFalse(moc.encryptMessagesAtRest)
        }
    }

    func testItThrowsAnError_WhenDatabaseKeyIsMissing_WhenEarIsDisabled() throws {
        // Given
        let validEncryptionKeys = self.validEncryptionKeys
        try uiMOC.enableEncryptionAtRest(encryptionKeys: validEncryptionKeys, skipMigration: true)
        uiMOC.encryptionKeys = nil

        try uiMOC.performGroupedAndWait { moc in
            // When
            XCTAssertThrowsError(try moc.disableEncryptionAtRest(encryptionKeys: try self.uiMOC.getEncryptionKeys())) { error in
                // Then
                guard case MigrationError.missingDatabaseKey = error else {
                    return XCTFail("Unexpected error thrown: \(error.localizedDescription)")
                }
            }

            XCTAssertTrue(moc.encryptMessagesAtRest)
        }
    }

    func testMigrationIsCanceled_WhenASingleInstanceFailsToMigrate() throws {
        // Given
        let encryptionKeys1 = validEncryptionKeys
        let encryptionKeys2 = validEncryptionKeys

        uiMOC.encryptMessagesAtRest = true

        let conversation = createConversation(in: uiMOC)

        uiMOC.encryptionKeys = encryptionKeys1
        try conversation.appendText(content: "Beep bloop")

        uiMOC.encryptionKeys = encryptionKeys2
        try conversation.appendText(content: "buzz buzzz")

        try uiMOC.performGroupedAndWait { moc in
            let results: [ZMGenericMessageData] = try self.fetchObjects()

            XCTAssertEqual(results.count, 2)
            XCTAssertTrue(moc.encryptMessagesAtRest)

            // When
            XCTAssertThrowsError(try moc.disableEncryptionAtRest(encryptionKeys: encryptionKeys1)) { error in
                // Then
                switch error {
                case let MigrationError.failedToMigrateInstances(type, _):
                    XCTAssertEqual(type.entityName(), ZMGenericMessageData.entityName())
                default:
                    XCTFail("Unexpected error thrown: \(error.localizedDescription)")
                }
            }

            // Then
            XCTAssertTrue(moc.encryptMessagesAtRest)
        }
    }

}

// MARK: - Helper Extensions

private extension ZMGenericMessageData {

    var unencryptedContent: String? {
        return underlyingMessage?.text.content
    }

}

private extension ZMConversation {

    var hasEncryptedDraftMessageData: Bool {
        return draftMessageData != nil && draftMessageNonce != nil
    }

    var unencryptedDraftMessageContent: String? {
        return draftMessage?.text
    }

}
