//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireNetworkSupport
import XCTest

@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class PullAllFeatureConfigsSyncTests: XCTestCase {

    private var sut: PullAllFeatureConfigsSync!
    private var api: MockFeatureConfigsAPI!
    private var store: MockFeatureConfigLocalStoreProtocol!

    override func setUp() async throws {
        api = MockFeatureConfigsAPI()
        store = MockFeatureConfigLocalStoreProtocol()
        sut = PullAllFeatureConfigsSync(api: api, store: store)
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        api.getFeatureConfigs_MockValue = Scaffolding.featureConfigs
        store.storeFeatureNameIsEnabledConfig_MockMethod = { _, _, _ in }

        // When
        try await sut.pull()

        // Then
        XCTAssertEqual(api.getFeatureConfigs_Invocations.count, 1)

        let storeInvocations = store.storeFeatureNameIsEnabledConfig_Invocations
        try XCTAssertCount(storeInvocations, count: 14)

        XCTAssertEqual(storeInvocations[0].name, .appLock)
        XCTAssertEqual(storeInvocations[0].isEnabled, true)
        XCTAssertEqual(
            storeInvocations[0].config as? Feature.AppLock.Config,
            Scaffolding.appLockFeatureConfig.toDomainModel()
        )

        XCTAssertEqual(storeInvocations[1].name, .apps)
        XCTAssertTrue(storeInvocations[1].isEnabled)
        XCTAssertNil(storeInvocations[1].config)

        XCTAssertEqual(storeInvocations[2].name, .classifiedDomains)
        XCTAssertEqual(storeInvocations[2].isEnabled, true)
        XCTAssertEqual(
            storeInvocations[2].config as? Feature.ClassifiedDomains.Config,
            Scaffolding.classifiedDomainsFeatureConfig.toDomainModel()
        )

        XCTAssertEqual(storeInvocations[3].name, .conferenceCalling)
        XCTAssertEqual(storeInvocations[3].isEnabled, true)
        XCTAssertEqual(
            storeInvocations[3].config as? Feature.ConferenceCalling.Config,
            Scaffolding.conferenceCallingFeatureConfig.toDomainModel()
        )

        XCTAssertEqual(storeInvocations[4].name, .conversationGuestLinks)
        XCTAssertTrue(storeInvocations[4].isEnabled)
        XCTAssertNil(storeInvocations[4].config)

        XCTAssertEqual(storeInvocations[5].name, .digitalSignature)
        XCTAssertTrue(storeInvocations[5].isEnabled)
        XCTAssertNil(storeInvocations[5].config)

        XCTAssertEqual(storeInvocations[6].name, .fileSharing)
        XCTAssertTrue(storeInvocations[6].isEnabled)
        XCTAssertNil(storeInvocations[6].config)

        XCTAssertEqual(storeInvocations[7].name, .selfDeletingMessages)
        XCTAssertTrue(storeInvocations[7].isEnabled)
        XCTAssertEqual(
            storeInvocations[7].config as? Feature.SelfDeletingMessages.Config,
            Scaffolding.selfDeletingMessagesFeatureConfig.toDomainModel()
        )

        XCTAssertEqual(storeInvocations[8].name, .mls)
        XCTAssertTrue(storeInvocations[8].isEnabled)
        XCTAssertEqual(
            storeInvocations[8].config as? Feature.MLS.Config,
            Scaffolding.mlsFeatureConfig.toDomainModel()
        )

        XCTAssertEqual(storeInvocations[9].name, .mlsMigration)
        XCTAssertTrue(storeInvocations[9].isEnabled)
        XCTAssertEqual(
            storeInvocations[9].config as? Feature.MLSMigration.Config,
            Scaffolding.mlsMigrationFeatureConfig.toDomainModel()
        )

        XCTAssertEqual(storeInvocations[10].name, .e2ei)
        XCTAssertTrue(storeInvocations[10].isEnabled)
        XCTAssertEqual(
            storeInvocations[10].config as? Feature.E2EI.Config,
            Scaffolding.endToEndIdentityFeatureConfig.toDomainModel()
        )

        XCTAssertEqual(storeInvocations[11].name, .consumableNotifications)
        XCTAssertTrue(storeInvocations[11].isEnabled)
        XCTAssertNil(storeInvocations[11].config)

        XCTAssertEqual(storeInvocations[12].name, .chatBubblesSimple)
        XCTAssertTrue(storeInvocations[12].isEnabled)
        XCTAssertNil(storeInvocations[12].config)

        XCTAssertEqual(storeInvocations[13].name, .cells)
        XCTAssertTrue(storeInvocations[13].isEnabled)
        XCTAssertNil(storeInvocations[13].config)
    }

}

private enum Scaffolding {

    static let featureConfigs: [FeatureConfig] = [
        .appLock(appLockFeatureConfig),
        .apps(appsFeatureConfig),
        .classifiedDomains(classifiedDomainsFeatureConfig),
        .conferenceCalling(conferenceCallingFeatureConfig),
        .conversationGuestLinks(conversationGuestLinksFeatureConfig),
        .digitalSignature(digitalSignatureFeatureConfig),
        .fileSharing(fileSharingFeatureConfig),
        .selfDeletingMessages(selfDeletingMessagesFeatureConfig),
        .mls(mlsFeatureConfig),
        .mlsMigration(mlsMigrationFeatureConfig),
        .endToEndIdentity(endToEndIdentityFeatureConfig),
        .consumableNotifications(consumableNotificationsFeatureConfig),
        .chatBubblesSimple(chatBubblesSimpleFeatureConfig),
        .cells(cellsFeatureConfig)
    ]

    static let appLockFeatureConfig = AppLockFeatureConfig(
        status: .enabled,
        isMandatory: true,
        inactivityTimeoutInSeconds: 2_147_483_647
    )

    static let appsFeatureConfig = AppsFeatureConfig(
        status: .enabled
    )

    static let classifiedDomainsFeatureConfig = ClassifiedDomainsFeatureConfig(
        status: .enabled,
        domains: ["example.com"]
    )

    static let conferenceCallingFeatureConfig = ConferenceCallingFeatureConfig(
        status: .enabled,
        useSFTForOneToOneCalls: false
    )

    static let conversationGuestLinksFeatureConfig = ConversationGuestLinksFeatureConfig(
        status: .enabled
    )

    static let digitalSignatureFeatureConfig = DigitalSignatureFeatureConfig(
        status: .enabled
    )

    static let fileSharingFeatureConfig = FileSharingFeatureConfig(
        status: .enabled
    )

    static let selfDeletingMessagesFeatureConfig = SelfDeletingMessagesFeatureConfig(
        status: .enabled,
        enforcedTimeoutSeconds: 2_147_483_647
    )

    static let mlsFeatureConfig = MLSFeatureConfig(
        status: .enabled,
        protocolToggleUsers: [.mockID1],
        defaultProtocol: .proteus,
        allowedCipherSuites: [
            .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
            .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
            .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519
        ],
        defaultCipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
        supportedProtocols: [.proteus]
    )

    static let mlsMigrationFeatureConfig = MLSMigrationFeatureConfig(
        status: .enabled,
        startTime: nil,
        finaliseRegardlessAfter: nil
    )

    static let endToEndIdentityFeatureConfig = EndToEndIdentityFeatureConfig(
        status: .enabled,
        acmeDiscoveryURL: "https://example.com",
        verificationExpiration: 9_223_372_036_854_776_000,
        crlProxy: "https://example.com",
        useProxyOnMobile: true
    )

    static let consumableNotificationsFeatureConfig = ConsumableNotificationsFeatureConfig(
        status: .enabled
    )

    static let chatBubblesSimpleFeatureConfig = ChatBubblesSimpleFeatureConfig(
        status: .enabled
    )

    static let cellsFeatureConfig = CellsFeatureConfig(
        status: .enabled
    )

}
