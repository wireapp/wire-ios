//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireDataModel
import WireUtilities
@testable import WireSyncEngine

class ZMUserSessionTests_CryptoStack: MessagingTest {

    var sut: ZMUserSession!
    var proteusFlag = DeveloperFlag.proteusViaCoreCrypto
    var mlsFlag = DeveloperFlag.enableMLSSupport

    override func setUp() {
        super.setUp()
        proteusFlag.isOn = true
        mlsFlag.isOn = true
        BackendInfo.apiVersion = .v5
    }

    override func tearDown() {
        sut.tearDown()
        sut = nil
        proteusFlag.isOn = false
        mlsFlag.isOn = false
        BackendInfo.apiVersion = nil
        super.tearDown()
    }

    @discardableResult
    override func createSelfClient() -> UserClient {
        var client: UserClient!

        // Log errors when creating the self client aren't important
        // in these tests.
        performIgnoringZMLogError {
            client = super.createSelfClient()
        }

        return client
    }

    func test_CryptoStackSetup_OnInit() {
        // GIVEN
        createSelfClient()

        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.domain = "example.domain.com"

        XCTAssertNil(syncMOC.coreCrypto)
        XCTAssertNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsService)
        XCTAssertNil(syncMOC.mlsEncryptionService)
        XCTAssertNil(syncMOC.mlsDecryptionService)

        // WHEN
        createSut(with: selfUser)

        // THEN
        XCTAssertNotNil(syncMOC.coreCrypto)
        XCTAssertNotNil(syncMOC.proteusService)
        XCTAssertNotNil(syncMOC.mlsService)
        XCTAssertNotNil(syncMOC.mlsEncryptionService)
        XCTAssertNotNil(syncMOC.mlsDecryptionService)
    }

    func test_CryptoStackSetup_OnInit_ProteusOnly() {
        // GIVEN
        mlsFlag.isOn = false
        createSelfClient()

        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.domain = "example.domain.com"

        XCTAssertNil(syncMOC.coreCrypto)
        XCTAssertNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsService)
        XCTAssertNil(syncMOC.mlsEncryptionService)
        XCTAssertNil(syncMOC.mlsDecryptionService)

        // WHEN
        createSut(with: selfUser)

        // THEN
        XCTAssertNotNil(syncMOC.coreCrypto)
        XCTAssertNotNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsService)
        XCTAssertNil(syncMOC.mlsEncryptionService)
        XCTAssertNil(syncMOC.mlsDecryptionService)
    }

    func test_CryptoStackSetup_OnInit_MLSOnly() {
        // GIVEN
        proteusFlag.isOn = false
        createSelfClient()

        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.domain = "example.domain.com"

        XCTAssertNil(syncMOC.coreCrypto)
        XCTAssertNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsService)
        XCTAssertNil(syncMOC.mlsEncryptionService)
        XCTAssertNil(syncMOC.mlsDecryptionService)

        // WHEN
        createSut(with: selfUser)

        // THEN
        XCTAssertNotNil(syncMOC.coreCrypto)
        XCTAssertNil(syncMOC.proteusService)
        XCTAssertNotNil(syncMOC.mlsService)
        XCTAssertNotNil(syncMOC.mlsEncryptionService)
        XCTAssertNotNil(syncMOC.mlsDecryptionService)
    }

    func test_CryptoStackSetup_DontSetupMLSIfAPIV5IsNotAvailable() throws {
        // GIVEN
        proteusFlag.isOn = false
        BackendInfo.apiVersion = .v1
        createSelfClient()

        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.domain = "example.domain.com"

        XCTAssertNil(syncMOC.coreCrypto)
        XCTAssertNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsService)
        XCTAssertNil(syncMOC.mlsEncryptionService)
        XCTAssertNil(syncMOC.mlsDecryptionService)

        // WHEN
        createSut(with: selfUser)

        // THEN
        XCTAssertNil(syncMOC.coreCrypto)
        XCTAssertNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsService)
        XCTAssertNil(syncMOC.mlsEncryptionService)
        XCTAssertNil(syncMOC.mlsDecryptionService)
    }

    func test_CryptoStackSetup_OnInit_AllFlagsOff() {
        // GIVEN
        proteusFlag.isOn = false
        mlsFlag.isOn = false
        createSelfClient()

        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.domain = "example.domain.com"

        XCTAssertNil(syncMOC.coreCrypto)
        XCTAssertNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsService)

        // WHEN
        createSut(with: selfUser)

        // THEN
        XCTAssertNil(syncMOC.coreCrypto)
        XCTAssertNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsService)
    }

    func test_CryptoStackSetup_WhenThereIsNoSelfClient() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.remoteIdentifier =  UUID.create()
        selfUser.domain = "example.domain.com"

        XCTAssertNil(syncMOC.coreCrypto)
        XCTAssertNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsService)
        XCTAssertNil(syncMOC.mlsEncryptionService)
        XCTAssertNil(syncMOC.mlsDecryptionService)

        // WHEN
        createSut(with: selfUser)

        // THEN
        XCTAssertNotNil(syncMOC.coreCrypto)
        XCTAssertNotNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsService)
        XCTAssertNil(syncMOC.mlsEncryptionService)
        XCTAssertNil(syncMOC.mlsDecryptionService)
    }

    func test_CryptoStackSetup_AfterRegisteringSelfClient() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.remoteIdentifier =  UUID.create()
        selfUser.domain = "example.domain.com"

        createSut(with: selfUser)

        XCTAssertNotNil(syncMOC.coreCrypto)
        XCTAssertNotNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsService)
        XCTAssertNil(syncMOC.mlsEncryptionService)
        XCTAssertNil(syncMOC.mlsDecryptionService)

        let client = createSelfClient()

        // WHEN
        sut.didRegisterSelfUserClient(client)

        // THEN
        XCTAssertNotNil(syncMOC.coreCrypto)
        XCTAssertNotNil(syncMOC.proteusService)
        XCTAssertNotNil(syncMOC.mlsService)
        XCTAssertNotNil(syncMOC.mlsEncryptionService)
        XCTAssertNotNil(syncMOC.mlsDecryptionService)
    }

    func test_ItCommitsPendingProposals_AfterQuickSyncCompletes() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.mlsGroupID = MLSGroupID("123".data(using: .utf8)!)
        conversation.commitPendingProposalDate = Date.distantPast

        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.remoteIdentifier =  UUID.create()
        selfUser.domain = "example.domain.com"

        createSut(with: selfUser)
        let client = createSelfClient()
        sut.didRegisterSelfUserClient(client)

        let controller = MockMLSService()
        sut.syncContext.mlsService = controller

        // WHEN
        sut.didFinishQuickSync()

        // THEN
        XCTAssertTrue(wait(withTimeout: 3.0) {
            controller.didCallCommitPendingProposals
        })
    }

    func createSut(with user: ZMUser) {
        let transportSession = RecordingMockTransportSession(
            cookieStorage: ZMPersistentCookieStorage(
                forServerName: "usersessiontest.example.com",
                userIdentifier: .create(),
                useCache: true
            ),
            pushChannel: MockPushChannel()
        )

        sut = ZMUserSession(
            userId: user.remoteIdentifier,
            transportSession: transportSession,
            mediaManager: MockMediaManager(),
            flowManager: FlowManagerMock(),
            analytics: nil,
            eventProcessor: MockUpdateEventProcessor(),
            strategyDirectory: MockStrategyDirectory(),
            syncStrategy: nil,
            operationLoop: nil,
            application: application,
            appVersion: "00000",
            coreDataStack: coreDataStack,
            configuration: .init(),
            sharedUserDefaults: sharedUserDefaults
        )
    }
}
