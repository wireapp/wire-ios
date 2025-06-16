//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import Combine
import Testing
import WireDomain
@testable import WireDataModelSupport
@testable import WireSyncEngine

class MLSGroupRepairAgentTests: XCTestCase {

    var sut: MLSGroupRepairAgent!
    var journal: Journal!
    var mockMLSService: MockMLSServiceInterface!
    var syncStateSubject: CurrentValueSubject<SyncState, Never>!

    override func setUp() {
        journal = Journal(
            userID: UUID(),
            storage: UserDefaults.temporary()
        )
        journal[.isSyncV2Enabled] = true
        mockMLSService = MockMLSServiceInterface()
        syncStateSubject = CurrentValueSubject(.idle)
        sut = MLSGroupRepairAgent(
            journal: journal,
            mlsService: mockMLSService,
            syncStatePublisher: syncStateSubject.eraseToAnyPublisher()
        )
    }

    override func tearDown() {
        sut = nil
        journal = nil
        mockMLSService = nil
        syncStateSubject = nil
    }

    func test_itRepairsGroupsWhenLiveSyncing() async throws {
        // Given
        let expectation = expectation(description: "repair conversation method called")
        let validGroupID = Data("valid-group".utf8).base64EncodedString()

        journal[.brokenMLSGroupIDs] = [validGroupID]

        mockMLSService.fetchAndRepairGroupWith_MockMethod = { _ in
            expectation.fulfill()
        }

        // When
        syncStateSubject.send(.liveSyncing(.ongoing))

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(mockMLSService.fetchAndRepairGroupWith_Invocations.count, 1)
    }

    func test_itDoesNotRepairGroupsWhenLiveSyncing() async {
        // Given
        mockMLSService.fetchAndRepairGroupWith_MockMethod = { _ in }

        // When
        syncStateSubject.send(.liveSyncing(.ongoing))

        // Then
        XCTAssertTrue(mockMLSService.fetchAndRepairGroupWith_Invocations.isEmpty)
    }

    func test_itDoesNotTryToRepairAfterMaxAttemptsReached() async {
        // Given
        let expectation1 = expectation(description: "repair conversation method called 1")
        let expectation2 = expectation(description: "repair conversation method called 2")
        let expectation3 = expectation(description: "repair conversation method called 3")
        let expectation4 = expectation(description: "repair conversation method not called")
        expectation4
            .isInverted =
            true // expectation 4 should not be called when we exceed the max attempts on a same broken MLS group

        let expectations: [Int: XCTestExpectation] = [
            1: expectation1,
            2: expectation2,
            3: expectation3,
            4: expectation4
        ]

        let validGroupID = Data("valid-group".utf8).base64EncodedString()
        var fetchAndRepairCalledCount = 0
        journal[.brokenMLSGroupIDs] = [validGroupID]

        mockMLSService.fetchAndRepairGroupWith_MockMethod = { _ in
            fetchAndRepairCalledCount += 1
            expectations[fetchAndRepairCalledCount]?.fulfill()
        }

        // When
        for _ in 1 ... 4 {
            syncStateSubject.send(.liveSyncing(.ongoing))
        }

        // Then
        await fulfillment(of: expectations.map(\.value), timeout: 5.0)
        XCTAssertEqual(journal[.brokenMLSGroupIDs], [])

    }

}
