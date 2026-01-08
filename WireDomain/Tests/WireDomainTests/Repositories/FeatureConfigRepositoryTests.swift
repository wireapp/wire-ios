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

import Combine
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import WireNetworkSupport
import XCTest

@testable import WireDomain
@testable import WireNetwork

final class FeatureConfigRepositoryTests: XCTestCase {

    private var sut: FeatureConfigRepository!
    private var featureConfigsAPI: MockFeatureConfigsAPI!
    private var featureConfigLocalStore: MockFeatureConfigLocalStoreProtocol!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!
    private var subscription: AnyCancellable?

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        featureConfigsAPI = MockFeatureConfigsAPI()
        featureConfigLocalStore = MockFeatureConfigLocalStoreProtocol()

        sut = FeatureConfigRepository(
            featureConfigsAPI: featureConfigsAPI,
            featureConfigLocalStore: featureConfigLocalStore
        )
    }

    override func tearDown() async throws {
        stack = nil
        featureConfigsAPI = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testPullFeatureConfigs_It_Invokes_Local_Store_Methods() async throws {
        // Mock

        let feature = await context.perform { [context] in
            Feature.updateOrCreate(
                havingName: .conversationGuestLinks,
                in: context
            ) { $0.status = .enabled }

            return Feature.fetch(
                name: .conversationGuestLinks,
                context: context
            )
        }

        featureConfigsAPI.getFeatureConfigs_MockValue = Scaffolding.featureConfigs
        featureConfigLocalStore.storeFeatureNameIsEnabledConfig_MockMethod = { _, _, _ in }
        featureConfigLocalStore.fetchFeatureName_MockValue = feature

        // When

        try await sut.pullFeatureConfigs()

        // Then

        XCTAssertEqual(
            featureConfigLocalStore.storeFeatureNameIsEnabledConfig_Invocations.count,
            Scaffolding.featureConfigs.count
        )
    }

    func testFetchFeatureConfig_It_Invokes_Local_Store_Methods_And_Retrieves_Correct_Config() async throws {
        // Mock

        let (feature, config) = try await context.perform { [context] in
            let config = try JSONEncoder().encode(Scaffolding.featureConfig)

            Feature.updateOrCreate(
                havingName: .appLock,
                in: context
            ) {
                $0.status = .enabled
                $0.config = config
            }

            let feature = Feature.fetch(
                name: .appLock,
                context: context
            )

            return (feature, config)
        }

        featureConfigLocalStore.fetchFeatureName_MockValue = feature
        featureConfigLocalStore.featureConfigFeature_MockMethod = { _ in (.enabled, config) }

        // When

        let localFeature = try await sut.fetchAppLock()

        // Then

        XCTAssertEqual(featureConfigLocalStore.featureConfigFeature_Invocations.count, 1)
        XCTAssertEqual(featureConfigLocalStore.fetchFeatureName_Invocations.count, 1)
        XCTAssertEqual(localFeature.status, .enabled)
        XCTAssertEqual(localFeature.config, Scaffolding.featureConfig)
    }

    func testObserveFeatureChanges_It_Invokes_Local_Store_Methods_And_Values_Are_Correctly_Emitted() async throws {
        // Given

        let feature = try await context.perform { [context] in
            let config = try JSONEncoder().encode(Scaffolding.featureConfig)

            Feature.updateOrCreate(
                havingName: .appLock,
                in: context
            ) {
                $0.status = .enabled
                $0.config = config
            }

            return Feature.fetch(
                name: .appLock,
                context: context
            )
        }

        let expectation = XCTestExpectation()
        var featureStates: [FeatureState] = []

        /// Start subscription
        subscription = sut.observeFeatureStates()
            .sink { featureState in
                featureStates.append(featureState)

                if featureStates.count == Scaffolding.featureConfigs.count {
                    expectation.fulfill()
                }
            }

        // Mock

        featureConfigsAPI.getFeatureConfigs_MockValue = Scaffolding.featureConfigs
        featureConfigLocalStore.storeFeatureNameIsEnabledConfig_MockMethod = { _, _, _ in }
        featureConfigLocalStore.fetchFeatureName_MockValue = feature

        // When

        _ = try await sut.pullFeatureConfigs()

        await fulfillment(of: [expectation], timeout: 5.0)

        // Then

        XCTAssertEqual(featureConfigsAPI.getFeatureConfigs_Invocations.count, 1)
        XCTAssertEqual(
            featureConfigLocalStore.storeFeatureNameIsEnabledConfig_Invocations.count,
            Scaffolding.featureConfigs.count
        )
    }

    private enum Scaffolding {

        nonisolated(unsafe) static let featureConfig = Feature.AppLock.Config(
            enforceAppLock: true,
            inactivityTimeoutSecs: .min
        )

        static let featureConfigs: [FeatureConfig] = [
            .appLock(
                .init(
                    status: .enabled,
                    isMandatory: true,
                    inactivityTimeoutInSeconds: 2_147_483_647
                )
            ),
            .apps(
                .init(status: .disabled)
            ),
            .classifiedDomains(
                .init(
                    status: .enabled,
                    domains: ["example.com"]
                )
            ),
            .conferenceCalling(
                .init(
                    status: .enabled,
                    useSFTForOneToOneCalls: false
                )
            ),
            .conversationGuestLinks(
                .init(
                    status: .enabled
                )
            ),
            .digitalSignature(
                .init(
                    status: .enabled
                )
            ),
            .fileSharing(
                .init(
                    status: .enabled
                )
            ),
            .selfDeletingMessages(
                .init(
                    status: .enabled,
                    enforcedTimeoutSeconds: 2_147_483_647
                )
            ),
            .mls(.init(
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
            )),
            .mlsMigration(.init(
                status: .enabled,
                startTime: nil,
                finaliseRegardlessAfter: nil
            )),
            .endToEndIdentity(.init(
                status: .enabled,
                acmeDiscoveryURL: "https://example.com",
                verificationExpiration: 9_223_372_036_854_776_000,
                crlProxy: "https://example.com",
                useProxyOnMobile: true
            )),
            .channels(.init(
                status: .enabled,
                allowedToCreateChannels: .admins,
                allowedToOpenChannels: .everyone
            )),
            .allowedGlobalOperations(
                AllowedGlobalOperationsFeatureConfig(
                    status: .enabled,
                    resetMLSConversations: true
                )
            ),
            .consumableNotifications(
                ConsumableNotificationsFeatureConfig(
                    status: .enabled
                )
            ),
            .cells(
                .init(status: .enabled)
            ),
            .cellsInternal(
                .init(
                    status: .enabled,
                    backendURL: URL(string: "https://wire.com")!
                )
            )
        ]

    }

}
