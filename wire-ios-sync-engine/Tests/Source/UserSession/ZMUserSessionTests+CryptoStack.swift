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
    var flag = DeveloperFlag.proteusViaCoreCrypto

    override func setUp() {
        super.setUp()
        flag.isOn = true
    }

    override func tearDown() {
        sut.tearDown()
        sut = nil
        flag.isOn = false
        super.tearDown()
    }

    func test_ItSetsUpCryptoStack_OnInit() {
        // GIVEN
        createSelfClient()

        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.domain = "example.domain.com"

        XCTAssertNil(syncMOC.coreCrypto)
        XCTAssertNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsController)

        // WHEN
        createSut(with: selfUser)

        // THEN
        XCTAssertNotNil(syncMOC.coreCrypto)
        XCTAssertNotNil(syncMOC.proteusService)
        XCTAssertNotNil(syncMOC.mlsController)
    }

    func test_ItDoesNotSetUpCryptoStack_WhenThereIsNoSelfClient() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.remoteIdentifier =  UUID.create()
        selfUser.domain = "example.domain.com"

        XCTAssertNil(syncMOC.coreCrypto)
        XCTAssertNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsController)

        // WHEN
        createSut(with: selfUser)

        // THEN
        XCTAssertNil(syncMOC.coreCrypto)
        XCTAssertNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsController)
    }

    func test_ItSetsUpCryptoStack_AfterRegisteringSelfClient() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.remoteIdentifier =  UUID.create()
        selfUser.domain = "example.domain.com"

        createSut(with: selfUser)

        XCTAssertNil(syncMOC.coreCrypto)
        XCTAssertNil(syncMOC.proteusService)
        XCTAssertNil(syncMOC.mlsController)

        let client = createSelfClient()

        // WHEN
        sut.didRegisterSelfUserClient(client)

        // THEN
        XCTAssertNotNil(syncMOC.coreCrypto)
        XCTAssertNotNil(syncMOC.proteusService)
        XCTAssertNotNil(syncMOC.mlsController)
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

        let controller = MockMLSController()
        sut.syncContext.mlsController = controller

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
                userIdentifier: .create()
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
            configuration: .init()
        )
    }
}
