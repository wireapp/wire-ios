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
@testable import Wire

// MARK: - TeamMetadataRefresherTests

final class TeamMetadataRefresherTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()

        mockSelfUser = .createSelfUser(name: "Alice", inTeam: UUID())
        mockSelfUserProvider = MockSelfUserProvider(providedSelfUser: mockSelfUser)
    }

    override func tearDown() {
        mockSelfUserProvider = nil
        mockSelfUser = nil

        super.tearDown()
    }

    func test_it_does_not_crash_if_no_self_user() throws {
        // Given
        let sut = TeamMetadataRefresher(selfUserProvider: mockSelfUserProvider)
        SelfUser.provider = nil

        // When
        sut.triggerRefreshIfNeeded()

        // Then nothing
    }

    func test_it_refreshes_for_a_team_member() {
        // Given
        let sut = TeamMetadataRefresher(selfUserProvider: mockSelfUserProvider)

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 0)

        // When
        sut.triggerRefreshIfNeeded()

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 1)
    }

    func test_it_does_not_refresh_for_non_team_member() {
        // Given
        let sut = TeamMetadataRefresher(selfUserProvider: mockSelfUserProvider)
        mockSelfUser.teamIdentifier = nil

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 0)

        // When
        sut.triggerRefreshIfNeeded()

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 0)
    }

    func test_it_refreshes_if_timeout_expired() {
        // Given
        let sut = TeamMetadataRefresher(refreshInterval: 0.5, selfUserProvider: mockSelfUserProvider)

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 0)

        // When
        sut.triggerRefreshIfNeeded()

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 1)

        // When
        let triggeredSecondRefresh = expectation(description: "triggered second refresh")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            sut.triggerRefreshIfNeeded()
            triggeredSecondRefresh.fulfill()
        }

        wait(for: [triggeredSecondRefresh], timeout: 2)

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 2)
    }

    func test_it_does_not_refresh_if_timeout_not_expired() {
        // Given
        let sut = TeamMetadataRefresher(refreshInterval: .oneMinute, selfUserProvider: mockSelfUserProvider)

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 0)

        // When
        sut.triggerRefreshIfNeeded()

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 1)

        // When
        sut.triggerRefreshIfNeeded()

        // Then
        XCTAssertEqual(mockSelfUser.refreshTeamDataCount, 1)
    }

    // MARK: Private

    private var mockSelfUser: MockUserType!

    private var mockSelfUserProvider: MockSelfUserProvider!
}

// MARK: - MockSelfUserProvider

private struct MockSelfUserProvider: SelfUserProvider {
    let providedSelfUser: UserType & EditableUserType
}
