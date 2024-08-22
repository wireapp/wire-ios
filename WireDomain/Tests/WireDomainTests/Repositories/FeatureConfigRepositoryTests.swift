//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

@testable import WireAPI
import WireAPISupport
import WireDataModel
import WireDataModelSupport
@testable import WireDomain
import XCTest

final class FeatureConfigRepositoryTests: XCTestCase {

    var sut: FeatureConfigRepository!
    var featureConfigsAPI: MockFeatureConfigsAPI!

    var stack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()

        stack = try await coreDataStackHelper.createStack()
        featureConfigsAPI = MockFeatureConfigsAPI()
        sut = FeatureConfigRepository(featureConfigsAPI: featureConfigsAPI,
                                      context: context)
    }

    override func tearDown() async throws {
        stack = nil
        featureConfigsAPI = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Tests

    func testPullFeatureConfigs() async throws {
        // Mock

        featureConfigsAPI.getFeatureConfigs_MockValue = Scaffolding.featureConfigs

        // When
        let featureConfigs = sut.pullFeatureConfigs()
        var storedFeatures: [Feature?] = []

        for try await featureConfig in featureConfigs {
            switch featureConfig {
            case .appLock:
                storedFeatures.append(Feature.fetch(name: .appLock, context: context))
            case .classifiedDomains:
                storedFeatures.append(Feature.fetch(name: .classifiedDomains, context: context))
            case .conferenceCalling:
                storedFeatures.append(Feature.fetch(name: .conferenceCalling, context: context))
            case .conversationGuestLinks:
                storedFeatures.append(Feature.fetch(name: .conversationGuestLinks, context: context))
            case .digitalSignature:
                storedFeatures.append(Feature.fetch(name: .digitalSignature, context: context))
            case .endToEndIdentity:
                storedFeatures.append(Feature.fetch(name: .e2ei, context: context))
            case .fileSharing:
                storedFeatures.append(Feature.fetch(name: .fileSharing, context: context))
            case .mls:
                storedFeatures.append(Feature.fetch(name: .mls, context: context))
            case .mlsMigration:
                storedFeatures.append(Feature.fetch(name: .mlsMigration, context: context))
            case .selfDeletingMessages:
                storedFeatures.append(Feature.fetch(name: .selfDeletingMessages, context: context))
            case .unknown:
                XCTFail()
            }
        }

        // Then
        let foundFeatures = storedFeatures.compactMap { $0 }
        XCTAssertEqual(foundFeatures.count, 10)
    }

}

private extension FeatureConfigRepositoryTests {
    enum Scaffolding {
        static let featureConfigs: [FeatureConfig] = [
            .appLock(.init(
                status: .enabled,
                isMandatory: true,
                inactivityTimeoutInSeconds: 2_147_483_647
            )
            ),
            .classifiedDomains(.init(
                status: .enabled,
                domains: ["example.com"]
            )
            ),
            .conferenceCalling(.init(
                status: .enabled,
                useSFTForOneToOneCalls: nil
            )
            ),
            .conversationGuestLinks(.init(
                status: .enabled)
            ),
            .digitalSignature(.init(
                status: .enabled)
            ),
            .fileSharing(.init(
                status: .enabled)
            ),
            .selfDeletingMessages(.init(
                status: .enabled,
                enforcedTimeoutSeconds: 2_147_483_647
            )
            ),
            .mls(.init(
                status: .enabled,
                protocolToggleUsers: [UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!],
                defaultProtocol: .proteus,
                allowedCipherSuites: [
                    .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
                    .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
                    .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519
                ],
                defaultCipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
                supportedProtocols: [.proteus]
            )),
            .mlsMigration(.init(status: .enabled,
                                startTime: nil,
                                finaliseRegardlessAfter: nil)),
            .endToEndIdentity(.init(status: .enabled,
                                    acmeDiscoveryURL: "https://example.com",
                                    verificationExpiration: 9_223_372_036_854_776_000,
                                    crlProxy: "https://example.com",
                                    useProxyOnMobile: true))
        ]

    }
}
