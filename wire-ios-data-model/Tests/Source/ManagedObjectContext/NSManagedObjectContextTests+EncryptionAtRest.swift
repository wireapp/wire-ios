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


}
