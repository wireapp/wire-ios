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

import WireDataModelSupport
import WireDomainSupport
import WireNetworkSupport
import WireTestingPackage
import XCTest
@testable import WireDataModel
@testable import WireDomain
@testable import WireNetwork

final class ConversationLabelsRepositoryTests: XCTestCase {

    private var sut: ConversationLabelsRepository!
    private var userPropertiesAPI: MockUserPropertiesAPI!
    private var conversationLabelsLocalStore: MockConversationLabelsLocalStoreProtocol!

    override func setUp() async throws {
        conversationLabelsLocalStore = MockConversationLabelsLocalStoreProtocol()

        userPropertiesAPI = MockUserPropertiesAPI()

        sut = ConversationLabelsRepository(
            userPropertiesAPI: userPropertiesAPI,
            conversationLabelsLocalStore: conversationLabelsLocalStore
        )
    }

    override func tearDown() async throws {
        sut = nil
        userPropertiesAPI = nil
        conversationLabelsLocalStore = nil
    }

    // MARK: - Tests

    func testPullConversationLabels_It_Invokes_Local_Store_And_User_Properties_API_Methods() async throws {
        // Mock

        userPropertiesAPI.getLabels_MockValue = [
            Scaffolding.conversationLabel1
        ]

        conversationLabelsLocalStore.setLabels_MockMethod = { _ in }

        // When

        try await sut.pullConversationLabels()

        // Then

        XCTAssertEqual(userPropertiesAPI.getLabels_Invocations.count, 1)
        XCTAssertEqual(conversationLabelsLocalStore.setLabels_Invocations.count, 1)
    }

    func testUpdateConversationLabels_It_Invokes_Local_Store_And_User_Properties_API_Methods() async throws {
        // Mock

        conversationLabelsLocalStore.setLabels_MockMethod = { _ in }

        // When

        try await sut.updateConversationLabels(
            [Scaffolding.conversationLabel1]
        )

        // Then

        XCTAssertEqual(conversationLabelsLocalStore.setLabels_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let conversationLabel1 = ConversationLabel(
            id: .mockID1,
            name: "ConversationLabel1",
            type: 0,
            conversationIDs: [
                .mockID2,
                .mockID3
            ]
        )

        static let conversationLabel2 = ConversationLabel(
            id: .mockID1,
            name: "ConversationLabel2",
            type: 0,
            conversationIDs: [
                .mockID2,
                .mockID3
            ]
        )
    }

}
