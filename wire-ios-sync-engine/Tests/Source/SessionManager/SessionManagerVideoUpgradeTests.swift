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

import AVFoundation
import WireDataModelSupport

@testable import WireDataModel
@testable import WireSyncEngine

final class SessionManagerVideoUpgradeTests: ZMUserSessionTestsBase {

    private var conversation: ZMConversation!
    private var handle: WireSyncEngine.CallHandle!
    private var appLock: MockAppLock!
    private var messageEncryptionService: MockEARMessageEncryptionServiceProtocol!

    override func setUp() {
        super.setUp()
        syncMOC.performGroupedAndWait {
            self.createSelfClient()
        }
        simulateLoggedInUser()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(sut.isLoggedIn)

        appLock = MockAppLock()
        sut.appLockController = appLock
        messageEncryptionService = MockEARMessageEncryptionServiceProtocol()
        messageEncryptionService.isLocked = false
        uiMOC.earMessageEncryptionService = messageEncryptionService
        conversation = ZMConversation(context: uiMOC)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group
        handle = .init(accountID: sut.account.userIdentifier, conversationID: conversation.remoteIdentifier!)
        XCTAssertFalse(sut.isLocked)
    }

    override func tearDown() {
        conversation = nil
        handle = nil
        appLock = nil
        messageEncryptionService = nil
        super.tearDown()
    }

    func testVideoUpgradeUsesTheCallsLoadedAccount() {
        // The selected account has no loaded session. The call belongs to another account.
        let selectedAccount = Account(userName: "Selected", userIdentifier: UUID())
        mockSessionManager.accountManager.addAndSelect(selectedAccount)
        defer { mockSessionManager.accountManager.remove(selectedAccount) }
        mockSessionManager.backgroundUserSessions = [sut.account.userIdentifier: sut]

        let channel = SessionManager.voiceChannelForVideoUpgrade(
            by: handle,
            sessions: mockSessionManager.backgroundUserSessions,
            isAuthenticated: true,
            cameraAuthorization: .authorized
        )

        XCTAssertTrue(channel?.conversation === conversation)
    }

    func testVideoUpgradeRejectsAnUnknownAccount() {
        handle = .init(accountID: UUID(), conversationID: conversation.remoteIdentifier!)
        XCTAssertNil(resolveVoiceChannel())
    }

    func testVideoUpgradeWaitsForTheCallsSessionToUnlock() {
        appLock.isLocked = true
        XCTAssertNil(resolveVoiceChannel())

        appLock.isLocked = false
        XCTAssertTrue(resolveVoiceChannel()?.conversation === conversation)
    }

    func testVideoUpgradeRequiresAuthenticatedAppState() {
        XCTAssertNil(resolveVoiceChannel(isAuthenticated: false))
    }

    func testVideoUpgradeRequiresAnUnlockedDatabase() {
        messageEncryptionService.isLocked = true
        XCTAssertNil(resolveVoiceChannel())
    }

    func testVideoUpgradeRequiresCameraPermission() {
        for status: AVAuthorizationStatus in [.notDetermined, .denied, .restricted] {
            XCTAssertNil(resolveVoiceChannel(cameraAuthorization: status))
        }
    }

    private func resolveVoiceChannel(
        isAuthenticated: Bool = true,
        cameraAuthorization: AVAuthorizationStatus = .authorized
    ) -> VoiceChannel? {
        SessionManager.voiceChannelForVideoUpgrade(
            by: handle,
            sessions: [sut.account.userIdentifier: sut],
            isAuthenticated: isAuthenticated,
            cameraAuthorization: cameraAuthorization
        )
    }
}
