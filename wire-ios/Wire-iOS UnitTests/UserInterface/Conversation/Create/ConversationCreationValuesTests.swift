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

import Testing
import WireDataModel

@testable import Wire

@Suite
struct ConversationCreationValuesTests {

    private let selfUser = MockUserType()

    // MARK: - allowApps safeguard

    @Test(
        "allowApps is false when the caller passes false, regardless of protocol or feature flags",
        arguments: MessageProtocol.allCases
    )
    func allowAppsIsFalseWhenCallerPassesFalse(messageProtocol: MessageProtocol) {
        let values = makeValues(
            allowApps: false,
            encryptionProtocol: messageProtocol,
            isAppsFeatureEnabled: true,
            areLegacyBotsAvailable: true
        )

        #expect(values.allowApps == false)
    }

    @Test(
        "with mls, allowApps follows isAppsFeatureEnabled and ignores legacy-bots availability",
        arguments: [
            (true, false, true),
            (true, true, true),
            (false, true, false),
            (false, false, false)
        ]
    )
    func allowAppsWithMLS(isAppsFeatureEnabled: Bool, areLegacyBotsAvailable: Bool, expected: Bool) {
        let values = makeValues(
            allowApps: true,
            encryptionProtocol: .mls,
            isAppsFeatureEnabled: isAppsFeatureEnabled,
            areLegacyBotsAvailable: areLegacyBotsAvailable
        )

        #expect(values.allowApps == expected)
    }

    @Test(
        "with proteus, allowApps follows areLegacyBotsAvailable and ignores apps-feature flag",
        arguments: [
            (false, true, true),
            (true, true, true),
            (true, false, false),
            (false, false, false)
        ]
    )
    func allowAppsWithProteus(isAppsFeatureEnabled: Bool, areLegacyBotsAvailable: Bool, expected: Bool) {
        let values = makeValues(
            allowApps: true,
            encryptionProtocol: .proteus,
            isAppsFeatureEnabled: isAppsFeatureEnabled,
            areLegacyBotsAvailable: areLegacyBotsAvailable
        )

        #expect(values.allowApps == expected)
    }

    @Test("with the mixed protocol, allowApps is always false even when all flags are enabled")
    func allowAppsWithMixedProtocolIsAlwaysFalse() {
        let values = makeValues(
            allowApps: true,
            encryptionProtocol: .mixed,
            isAppsFeatureEnabled: true,
            areLegacyBotsAvailable: true
        )

        #expect(values.allowApps == false)
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
