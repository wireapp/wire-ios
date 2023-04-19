//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

final class EARServiceTests: DatabaseBaseTest {

    var sut: EARService!
    var keyRepository: MockEARKeyRepositoryInterface!

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()

        let coreDataStack = createStorageStackAndWaitForCompletion(userID: accountID)

        keyRepository = MockEARKeyRepositoryInterface()

        sut = EARService(
            accountID: accountID,
            keyRepository: keyRepository,
            databaseContexts: coreDataStack.viewContext, coreDataStack.syncContext
        )
    }

    override func tearDown() {
        sut = nil
        keyRepository = nil
        super.tearDown()
    }

    // MARK: - Enable EAR

    func test_EnableEncryptionAtRest() throws {
        XCTFail()
    }

    func test_EnableEncryptionAtRest_SkipMigration() throws {
        XCTFail()
    }

    // MARK: - Disable EAR

    func test_DisableEncryptionAtRest() throws {
        XCTFail()
    }

    func test_DisableEncryptionAtRest_SkipMigration() throws {
        XCTFail()
    }

    // MARK: - Lock database

    func test_LockDatabase() throws {
        XCTFail()
    }

    // MARK: - Unlock database

    func test_UnlockDatabase() throws {
        XCTFail()
    }

    // MARK: - Fetch public keys

    func test_FetchPublicKeys() throws {
        XCTFail()
    }

    // MARK: - Fetch private keys

    func test_FetchPrivateKeys() throws {
        XCTFail()
    }

}
