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

import XCTest
import WireTesting
@testable import WireSyncEngine

// class SessionManagerTests_CryptoboxMigration: IntegrationTest {
//
//    var proteusViaCoreCryptoFlag = DeveloperFlag.proteusViaCoreCrypto
//    var mockCryptoboxMigrationManager: MockCryptoboxMigrationManagerInterface!
//
//    override func setUp() {
//        super.setUp()
//        mockCryptoboxMigrationManager = MockCryptoboxMigrationManagerInterface()
//        createSelfUserAndConversation()
//
//        mockCryptoboxMigrationManager.performMigrationAccountDirectorySyncContext_MockMethod = { _, _ in }
//        mockCryptoboxMigrationManager.completeMigrationSyncContext_MockMethod = { _ in }
////        sessionManager?.cryptoboxMigrationManager = mockCryptoboxMigrationManager
//    }
//
//    override func tearDown() {
//        mockCryptoboxMigrationManager = nil
//        proteusViaCoreCryptoFlag.isOn = false
//        super.tearDown()
//    }
//
//    func testItPerformsMigrationIfNeeded() {
//        // Given
//        mockCryptoboxMigrationManager.isMigrationNeededAccountDirectory_MockValue = true
//
//        // When
//        XCTAssert(login())
//
//        // Then
//        XCTAssertEqual(mockCryptoboxMigrationManager.performMigrationAccountDirectorySyncContext_Invocations.count, 1)
//        XCTAssertEqual(mockCryptoboxMigrationManager.completeMigrationSyncContext_Invocations.count, 1)
//    }
//
//    func testItDoesNotPerformMigration() {
//        // Given
//        mockCryptoboxMigrationManager.isMigrationNeededAccountDirectory_MockValue = false
//
//        // When
//        XCTAssert(login())
//
//        // Then
//        XCTAssertTrue(mockCryptoboxMigrationManager.performMigrationAccountDirectorySyncContext_Invocations.isEmpty)
//        XCTAssertEqual(mockCryptoboxMigrationManager.completeMigrationSyncContext_Invocations.count, 1)
//    }
//
// }
