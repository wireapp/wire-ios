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

import WireDataModelSupport
import XCTest
@testable import WireRequestStrategy

final class PushSupportedProtocolsActionHandlerTests: ActionHandlerTestBase<
    PushSupportedProtocolsAction,
    PushSupportedProtocolsActionHandler
> {
    // MARK: - Properties

    private var stack: CoreDataStack!
    private let coreDataStackHelper = CoreDataStackHelper()

    private var syncContext: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()
        handler = PushSupportedProtocolsActionHandler(context: syncContext)
        action = PushSupportedProtocolsAction(supportedProtocols: [.proteus, .mls])
    }

    override func tearDown() async throws {
        stack = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    func testPushSupportedProtocolsRequestGeneration_APIV4() throws {
        // given
        // when
        let request = handler.request(for: action, apiVersion: .v4)

        // then
        XCTAssertNil(request)
    }

    func testPushSupportedProtocolsRequestGeneration_APIV5() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v5/self/supported-protocols",
            expectedMethod: .put,
            apiVersion: .v5
        )
    }

    func testActionHandlerHandlesSuccessResponse() {
        let statusCode = 200

        let result: PushSupportedProtocolsAction.Result? = test_itHandlesSuccess(status: statusCode, apiVersion: .v4)

        // WHEN, THEN
        XCTAssertNotNil(result)
    }
}
