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

import XCTest
@testable import WireRequestStrategy
import WireDataModelSupport

final class PushSupportedProtocolsActionHandlerTests: ActionHandlerTestBase<PushSupportedProtocolsAction, PushSupportedProtocolsActionHandler> {

    // MARK: - Properties

    private var stack: CoreDataStack!
    private let coreDataStackHelper = CoreDataStackHelper()

    private var syncContext: NSManagedObjectContext {
        return stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()
        self.handler = PushSupportedProtocolsActionHandler(context: syncContext)
        self.action = PushSupportedProtocolsAction(supportedProtocols: [.proteus, .mls])
    }

    override func tearDown() async throws {
        stack = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    func testActionHandlerCreatesValidRequest_APIVersionFour() {
        let request = self.handler.request(for: self.action, apiVersion: .v4)
        XCTAssertNotNil(request, "Handler should create a valid request for supported API versions and protocols")
    }

    func testActionHandlerDoesNotCreateValidRequest_APIVersionThree() {
        let request = self.handler.request(for: self.action, apiVersion: .v3)
        XCTAssertNil(request, "Handler should not create a valid request for supported API versions and protocols")
    }

    func testActionHandlerHandlesSuccessResponse() {
        let statusCode = 200

        let result: PushSupportedProtocolsAction.Result? = test_itHandlesSuccess(status: statusCode, apiVersion: .v4)

        // WHEN, THEN
        XCTAssertNotNil(result)
    }

}
