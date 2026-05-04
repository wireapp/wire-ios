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

import WireNetwork
import WireTestingPackage
import XCTest

@testable import Wire

@MainActor
final class ConversationCreationControllerSnapshotTests: XCTestCase {

    // MARK: - Properties

    var sut: ConversationCreationController!

    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    override func setUp() {
        snapshotHelper = SnapshotHelper()
        accentColor = .purple
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        UIColor.setAccentOverride(nil)
    }

    // MARK: - Snapshot Tests

    func testForEditingTextField() async {
        await createSut(isTeamMember: false)

        snapshotHelper.verify(matching: sut)
    }

    func testTeamGroupOptions() async {
        await createSut(isTeamMember: true)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )
    }

    func testTeamGroupOptions_withoutServices() async {
        await createSut(isTeamMember: true, messageProtocol: .mls)

        snapshotHelper.verify(matching: sut)
    }

    // MARK: - Helper Method

    private func createSut(
        isTeamMember: Bool,
        messageProtocol: Feature.MLS.Config.MessageProtocol = .proteus
    ) async {
        let mockSelfUser = MockUserType.createSelfUser(name: "Alice", inTeam: isTeamMember ? UUID() : nil)
        let mockUserSession = UserSessionMock(mockUser: mockSelfUser)
        mockUserSession.isWireDriveEnabled = true
        mockUserSession.mlsFeature = .init(
            status: .enabled,
            config: .init(
                defaultProtocol: messageProtocol,
                defaultCipherSuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519
            )
        )

        sut = ConversationCreationController(
            preSelectedParticipants: nil,
            userSession: mockUserSession,
            isAppsFeatureEnabled: false,
            areLegacyBotsAvailable: false
        )
    }
}
