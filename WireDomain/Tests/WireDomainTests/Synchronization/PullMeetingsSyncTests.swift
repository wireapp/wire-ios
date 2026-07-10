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

import WireCallingDomain
import WireCallingDomainSupport
import XCTest

@testable import WireDomain

final class PullMeetingsSyncTests: XCTestCase {

    private var sut: PullMeetingsSync!
    private var repository: MeetingRepositoryProtocolMock!

    override func setUp() async throws {
        repository = MeetingRepositoryProtocolMock()
        sut = PullMeetingsSync(repository: repository)
    }

    override func tearDown() async throws {
        repository = nil
        sut = nil
    }

    func testPull() async throws {
        // When
        try await sut.pull()

        // Then
        XCTAssertEqual(repository.pullMeetingsVoidCallsCount, 1)
    }

    func testPull_ErrorsAreRethrown() async {
        // Mock
        repository.pullMeetingsVoidThrowableError = MockError()

        // When / Then
        do {
            try await sut.pull()
            XCTFail("expected an error to be thrown")
        } catch {
            // expected
        }
    }

}

private struct MockError: Error {}
