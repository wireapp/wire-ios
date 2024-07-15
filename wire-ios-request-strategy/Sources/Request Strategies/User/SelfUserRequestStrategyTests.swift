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

@testable import WireRequestStrategy
import XCTest

final class SelfUserRequestStrategyTests: MessagingTestBase {

    var sut: SelfUserRequestStrategy!
    var applicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()

        syncMOC.performGroupedAndWait {
            self.applicationStatus = MockApplicationStatus()
            self.applicationStatus.mockSynchronizationState = .online
            self.sut = SelfUserRequestStrategy(
                withManagedObjectContext: syncMOC,
                applicationStatus: self.applicationStatus
            )
        }
    }

    override func tearDown() {
        sut = nil
        applicationStatus = nil

        super.tearDown()
    }

    // MARK: - Supported protocols

    func test_ItGeneratesANoRequest_givenAPIVersionV4_WhenSupportedProtocolsChanges() throws {
        // GIVEN
        var action = PushSupportedProtocolsAction(supportedProtocols: [.proteus, .mls])
        action.perform(in: syncMOC.notificationContext) { _ in }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // WHEN
            let request = self.sut.nextRequest(for: .v4)
            XCTAssertNil(request)
        }
    }

    func test_ItGeneratesARequest_givenAPIVersionV5_WhenSupportedProtocolsChanges() throws {
        // GIVEN
        var action = PushSupportedProtocolsAction(supportedProtocols: [.proteus, .mls])
        action.perform(in: syncMOC.notificationContext) { _ in }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // WHEN
            guard let request = self.sut.nextRequest(for: .v5) else {
                return XCTFail("expected a request")
            }

            // Then
            XCTAssertEqual(request.path, "/v5/self/supported-protocols")
            XCTAssertEqual(request.method, .put)

            guard
                let payload = request.payload?.asDictionary(),
                let supportedProtocols = payload["supported_protocols"] as? [String]
            else {
                return XCTFail("expected a payload")
            }

            XCTAssertEqual(
                Set(supportedProtocols),
                Set(["mls", "proteus"])
            )
        }
    }
}
