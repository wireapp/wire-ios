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

import Combine
import XCTest
@testable import WireDataModelSupport
@testable import WireDomain

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
            mlsService: mockMLSService
        )
    }

    override func tearDown() {
        sut = nil
        journal = nil
        mockMLSService = nil
        syncStateSubject = nil
    }

    func test_itInvokesMLSService_Fetch_And_Repair_Group() async throws {
        // Given
        let validGroupID = Data("valid-group".utf8).base64EncodedString()
        journal[.brokenMLSGroupIDs] = [validGroupID]

        mockMLSService.fetchAndRepairGroupWithShouldPerformIncrementalSync_MockMethod = { _, _ in }

        // When
        await sut.repairConversations()

        // Then
        XCTAssertEqual(
            mockMLSService.fetchAndRepairGroupWithShouldPerformIncrementalSync_Invocations.count,
            1
        )

        XCTAssertEqual(journal[.brokenMLSGroupIDs], [])
    }

}
