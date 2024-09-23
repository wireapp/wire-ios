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

final class UserPushRemoveEventProcessorTests: XCTestCase {

    var sut: UserPushRemoveEventProcessor!

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
        sut = UserPushRemoveEventProcessor(
            repository: UserRepository(
                context: context,
                usersAPI: MockUsersAPI()
            )
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Removes_Push_Token_From_Defaults() async throws {
        // Given

        let defaults = UserDefaults.standard
        let data = try JSONEncoder().encode(Scaffolding.pushToken)
        defaults.set(data, forKey: "PushToken")

        // When

        sut.processEvent()

        // Then

        let pushToken = defaults.object(forKey: "PushToken")
        XCTAssertNil(pushToken)
    }

}

extension UserPushRemoveEventProcessorTests {
    enum Scaffolding {
        static let deviceToken = Data(repeating: 0x41, count: 10)
        static let pushToken = PushToken(
            deviceToken: deviceToken,
            appIdentifier: "com.wire",
            transportType: "APNS_VOIP",
            tokenType: .voip
        )
    }
}
