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
import WireDataModelSupport
import XCTest
@testable import WireDomain

final class FeatureConfigLocalStoreTests: XCTestCase {

    private var sut: FeatureConfigLocalStore!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        sut = FeatureConfigLocalStore(context: context)
    }

    override func tearDown() async throws {
        stack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testStoreFeature_It_Stores_Feature_Locally() async throws {
        // When

        await sut.storeFeature(
            name: .appLock,
            isEnabled: true,
            config: Scaffolding.featureConfig
        )

        // Then

        await context.perform { [context] in
            let feature = Feature.fetch(name: .appLock, context: context)
            XCTAssertNotNil(feature)
        }
    }

    func testFetchFeature_It_Retrieves_Feature_With_Correct_Config() async throws {
        // Given

        try await context.perform { [context] in
            let config = try JSONEncoder().encode(Scaffolding.featureConfig)
            Feature.updateOrCreate(
                havingName: .appLock,
                in: context
            ) {
                $0.status = .enabled
                $0.config = config
            }
        }

        // When

        let feature = try await sut.fetchFeature(
            name: .appLock
        )

        // Then

        try await context.perform {
            XCTAssertEqual(feature.name, .appLock)
            let appLockConfig = try JSONDecoder().decode(
                Feature.AppLock.Config.self,
                from: try XCTUnwrap(feature.config)
            )
            XCTAssertEqual(Scaffolding.featureConfig, appLockConfig)
        }
    }

    private enum Scaffolding {
        nonisolated(unsafe) static let featureConfig = Feature.AppLock.Config(
            enforceAppLock: true,
            inactivityTimeoutSecs: .min
        )
    }

}
