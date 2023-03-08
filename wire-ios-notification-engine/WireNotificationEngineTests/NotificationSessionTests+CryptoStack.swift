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

@testable import WireNotificationEngine
import XCTest
import Foundation
import WireUtilities
import WireTransport

class NotificationSessionTests_CryptoStack: BaseTest {

    private var proteusFlag = DeveloperFlag.proteusViaCoreCrypto
    private var mlsFlag = DeveloperFlag.enableMLSSupport

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()
        proteusFlag.isOn = false
        mlsFlag.isOn = false
        BackendInfo.apiVersion = .v2
    }

    override func tearDown() {
        proteusFlag.isOn = false
        mlsFlag.isOn = false
        BackendInfo.apiVersion = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_CryptoStackSetup_OnInit_ProteusOnly() throws {
        // GIVEN
        proteusFlag.isOn = true

        let context = coreDataStack.syncContext

        XCTAssertNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)

        // WHEN
        _ = try createNotificationSession()

        // THEN
        XCTAssertNil(context.mlsController)
        XCTAssertNotNil(context.proteusService)
        XCTAssertNotNil(context.coreCrypto)
    }

    func test_CryptoStackSetup_OnInit_MLSOnly() throws {
        // GIVEN
        mlsFlag.isOn = true

        let context = coreDataStack.syncContext

        XCTAssertNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)

        // WHEN
        _ = try createNotificationSession()

        // THEN
        XCTAssertNotNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNotNil(context.coreCrypto)
    }

    func test_CryptoStackSetup_DontSetupMLSIfAPIV2IsNotAvailable() throws {
        // GIVEN
        mlsFlag.isOn = true
        BackendInfo.apiVersion = .v1

        let context = coreDataStack.syncContext

        XCTAssertNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)

        // WHEN
        _ = try createNotificationSession()

        // THEN
        XCTAssertNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)
    }


    func test_CryptoStackSetup_OnInit_ProteusAndMLS() throws {
        // GIVEN
        proteusFlag.isOn = true
        mlsFlag.isOn = true

        let context = coreDataStack.syncContext

        XCTAssertNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)

        // WHEN
        _ = try createNotificationSession()

        // THEN
        XCTAssertNotNil(context.mlsController)
        XCTAssertNotNil(context.proteusService)
        XCTAssertNotNil(context.coreCrypto)
    }

    func test_CryptoStackSetup_OnInit_AllFlagsDisabled() throws {
        // GIVEN
        XCTAssertFalse(proteusFlag.isOn)
        XCTAssertFalse(mlsFlag.isOn)

        let context = coreDataStack.syncContext

        XCTAssertNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)

        // WHEN
        _ = try createNotificationSession()

        // THEN
        XCTAssertNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)
    }

}
