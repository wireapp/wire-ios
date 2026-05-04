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

import WireNetworkSupport
import XCTest
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class PullConversationLabelsSyncTests: XCTestCase {

    private var sut: PullConversationLabelsSync!
    private var api: MockUserPropertiesAPI!
    private var store: MockConversationLabelsLocalStoreProtocol!

    override func setUp() async throws {
        api = MockUserPropertiesAPI()
        store = MockConversationLabelsLocalStoreProtocol()
        sut = PullConversationLabelsSync(api: api, store: store)
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        api.getLabels_MockValue = Scaffolding.remoteLabels
        store.setLabels_MockMethod = { _ in }

        // When
        try await sut.pull()

        // Then
        XCTAssertEqual(api.getLabels_Invocations.count, 1)

        try XCTAssertCount(store.setLabels_Invocations, count: 1)
        XCTAssertEqual(store.setLabels_Invocations[0], Scaffolding.localLabels)
    }

}

private enum Scaffolding {

    static let remoteLabels = [
        ConversationLabel(
            id: UUID(),
            name: "label 1",
            type: 0,
            conversationIDs: [UUID()]
        ),
        ConversationLabel(
            id: UUID(),
            name: "label 2",
            type: 1,
            conversationIDs: [UUID()]
        )
    ]

    static var localLabels: [ConversationLabelInfo] {
        remoteLabels.map {
            $0.toDomainModel()
        }
    }

}
