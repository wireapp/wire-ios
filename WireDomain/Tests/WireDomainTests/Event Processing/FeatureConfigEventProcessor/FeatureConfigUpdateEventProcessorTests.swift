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

import Foundation
import WireAPI
import WireAPISupport
import WireDataModel
import WireDataModelSupport
import XCTest

@testable import WireDomain

final class FeatureConfigUpdateEventProcessorTests: XCTestCase {

    var sut: FeatureConfigUpdateEventProcessor!

    var coreDataStack: CoreDataStack!
    var coreDataStackHelper: CoreDataStackHelper!
    var modelHelper: ModelHelper!

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = FeatureConfigUpdateEventProcessor(
            repository: FeatureConfigRepository(
                featureConfigsAPI: MockFeatureConfigsAPI(),
                context: context
            )
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        modelHelper = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        coreDataStack = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Updates_Feature_Config_Locally() async throws {
        // Given

        try await context.perform { [context] in
            let config = try JSONEncoder().encode(Scaffolding.config)
            Feature.updateOrCreate(havingName: .mls, in: context) { feature in
                feature.status = .enabled
                feature.config = config
            }
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let feature = try XCTUnwrap(Feature.fetch(name: .mls, context: context))
            let data = try XCTUnwrap(feature.config)
            let config = try JSONDecoder().decode(Feature.MLS.Config.self, from: data)
            XCTAssertEqual(feature.status, .disabled)
            XCTAssertEqual(config.supportedProtocols, [.mls])
        }
    }
}

private extension FeatureConfigUpdateEventProcessorTests {
    enum Scaffolding {
        static let event = FeatureConfigUpdateEvent(
            featureConfig: .mls(updatedConfig)
        )

        static let updatedConfig = MLSFeatureConfig(
            status: .disabled, /// updated property
            protocolToggleUsers: [UUID()],
            defaultProtocol: .proteus,
            allowedCipherSuites: [.MLS_128_DHKEMP256_AES128GCM_SHA256_P256],
            defaultCipherSuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
            supportedProtocols: [.mls] /// updated property
        )

        static let config = Feature.MLS.Config(
            protocolToggleUsers: [UUID()],
            defaultProtocol: .proteus,
            allowedCipherSuites: [.MLS_128_DHKEMP256_AES128GCM_SHA256_P256],
            defaultCipherSuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
            supportedProtocols: [.proteus]
        )
    }
}
