////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

final class SelfUserRequestStrategyTests: MessagingTestBase {

    var sut: SelfUserRequestStrategy!
    var applicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()

        syncMOC.performGroupedAndWait { context in
            self.applicationStatus = MockApplicationStatus()
            self.applicationStatus.mockSynchronizationState = .online
            self.sut = SelfUserRequestStrategy(
                withManagedObjectContext: context,
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

    func test_ItGeneratesARequest_WhenSupportedProtocolsChanges() throws {
        syncMOC.performGroupedAndWait { context in
            // Given
            let selfUser = ZMUser.selfUser(in: context)
            selfUser.needsToBeUpdatedFromBackend = false
            selfUser.supportedProtocols = [.proteus, .mls]

            self.sut.contextChangeTrackers.forEach {
                $0.addTrackedObjects([selfUser])
            }

            // When
            guard let request = self.sut.nextRequest(for: .v4) else {
                return XCTFail("expected a request")
            }

            // Then
            XCTAssertEqual(request.path, "/v4/self/supported-protocols")
            XCTAssertEqual(request.method, .put)

            guard
                let payload = request.payload?.asDictionary(),
                let supportedProtocols = payload["supported_protocols"] as? [String]
            else {
                return XCTFail("expected a payload")
            }

            XCTAssertEqual(
                Set(supportedProtocols),
                Set(selfUser.supportedProtocols.map(\.rawValue))
            )
        }

    }

}
