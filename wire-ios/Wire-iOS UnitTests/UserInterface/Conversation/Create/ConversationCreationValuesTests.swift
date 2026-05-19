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

import WireDataModel
import XCTest

@testable import Wire

final class ConversationCreationValuesTests: XCTestCase {

    // MARK: - Properties

    private var selfUser: MockUserType!

    // MARK: - Set up

    override func setUp() {
        super.setUp()
        selfUser = MockUserType()
    }

    override func tearDown() {
        selfUser = nil
        super.tearDown()
    }

    // MARK: - allowApps safeguard

    func test_AllowApps_IsFalse_WhenCallerPassesFalse() {
        for messageProtocol in MessageProtocol.allCases {
            let values = makeValues(
                allowApps: false,
                encryptionProtocol: messageProtocol,
                isAppsFeatureEnabled: true,
                areLegacyBotsAvailable: true
            )

            XCTAssertFalse(values.allowApps, "expected false for \(messageProtocol)")
        }
    }

    func test_AllowApps_MLS_IsTrue_OnlyWhenAppsFeatureIsEnabled() {
        let enabled = makeValues(
            allowApps: true,
            encryptionProtocol: .mls,
            isAppsFeatureEnabled: true,
            areLegacyBotsAvailable: false
        )
        XCTAssertTrue(enabled.allowApps)

        // With mls, the legacy-bots flag must not influence the result.
        let disabled = makeValues(
            allowApps: true,
            encryptionProtocol: .mls,
            isAppsFeatureEnabled: false,
            areLegacyBotsAvailable: true
        )
        XCTAssertFalse(disabled.allowApps)
    }

    func test_AllowApps_Proteus_IsTrue_OnlyWhenLegacyBotsAreAvailable() {
        let available = makeValues(
            allowApps: true,
            encryptionProtocol: .proteus,
            isAppsFeatureEnabled: false,
            areLegacyBotsAvailable: true
        )
        XCTAssertTrue(available.allowApps)

        // With proteus, the apps-feature flag must not influence the result.
        let unavailable = makeValues(
            allowApps: true,
            encryptionProtocol: .proteus,
            isAppsFeatureEnabled: true,
            areLegacyBotsAvailable: false
        )
        XCTAssertFalse(unavailable.allowApps)
    }

    func test_AllowApps_Mixed_IsAlwaysFalse() {
        // The `mixed` protocol is intentionally not covered by either branch of the safeguard.
        let values = makeValues(
            allowApps: true,
            encryptionProtocol: .mixed,
            isAppsFeatureEnabled: true,
            areLegacyBotsAvailable: true
        )

        XCTAssertFalse(values.allowApps)
    }

    // MARK: - Helpers

    private func makeValues(
        allowApps: Bool,
        encryptionProtocol: MessageProtocol,
        isAppsFeatureEnabled: Bool,
        areLegacyBotsAvailable: Bool
    ) -> ConversationCreationValues {
        ConversationCreationValues(
            isChannel: false,
            isAppsFeatureEnabled: isAppsFeatureEnabled,
            areLegacyBotsAvailable: areLegacyBotsAvailable,
            allowApps: allowApps,
            encryptionProtocol: encryptionProtocol,
            selfUser: selfUser
        )
    }

}
