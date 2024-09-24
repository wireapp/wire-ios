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

import WireAPI
@testable import WireDomain
import WireDomainSupport
import XCTest

final class FeatureConfigUpdateEventProcessorTests: XCTestCase {

    var sut: FeatureConfigUpdateEventProcessor!
    var featureConfigRepository: MockFeatureConfigRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        featureConfigRepository = MockFeatureConfigRepositoryProtocol()
        sut = FeatureConfigUpdateEventProcessor(repository: featureConfigRepository)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        sut = nil
        featureConfigRepository = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Update_Feature_Config_Repo_Method() async throws {
        // Given

        let event = FeatureConfigUpdateEvent(
            featureConfig: Scaffolding.config
        )

        // Mock

        featureConfigRepository.updateFeatureConfig_MockMethod = { _ in }

        // When

        try await sut.processEvent(event)

        // Then

        XCTAssertEqual(featureConfigRepository.updateFeatureConfig_Invocations, [Scaffolding.config])
    }

    private enum Scaffolding {
        static let config = FeatureConfig.mls(MLSFeatureConfig(
            status: .disabled,
            protocolToggleUsers: [UUID()],
            defaultProtocol: .proteus,
            allowedCipherSuites: [.MLS_128_DHKEMP256_AES128GCM_SHA256_P256],
            defaultCipherSuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
            supportedProtocols: [.mls]
        ))
    }
}
