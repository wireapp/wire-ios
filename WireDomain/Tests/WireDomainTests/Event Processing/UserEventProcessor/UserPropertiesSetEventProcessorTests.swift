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

@testable import WireAPI
@testable import WireDomain
import WireDomainSupport
import XCTest

final class UserPropertiesSetEventProcessorTests: XCTestCase {

    var sut: UserPropertiesSetEventProcessor!
    var userRepository: MockUserRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        userRepository = MockUserRepositoryProtocol()
        sut = UserPropertiesSetEventProcessor(repository: userRepository)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        sut = nil
        userRepository = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Update_User_Property_Repo_Method() async throws {
        // Given
        let labels = [Scaffolding.conversationLabel1, Scaffolding.conversationLabel2]
        let event = UserPropertiesSetEvent(
            property: .conversationLabels(labels)
        )

        // Mock

        userRepository.updateUserProperty_MockMethod = { _ in }

        // When

        try await sut.processEvent(event)

        // Then

        XCTAssertEqual(userRepository.updateUserProperty_Invocations, [.conversationLabels(labels)])
    }

    private enum Scaffolding {
        static let conversationLabel1 = ConversationLabel(
            id: UUID(uuidString: "f3d302fb-3fd5-43b2-927b-6336f9e787b0")!,
            name: "ConversationLabel1",
            type: 0,
            conversationIDs: [
                UUID(uuidString: "ffd0a9af-c0d0-4748-be9b-ab309c640dde")!,
                UUID(uuidString: "03fe0d05-f0d5-4ee4-a8ff-8d4b4dcf89d8")!
            ]
        )
        static let conversationLabel2 = ConversationLabel(
            id: UUID(uuidString: "2AA27182-AA54-4D79-973E-8974A3BBE375")!,
            name: "ConversationLabel2",
            type: 0,
            conversationIDs: [
                UUID(uuidString: "ceb3f577-3b22-4fe9-8ffd-757f29c47ffc")!,
                UUID(uuidString: "eca55fdb-8f81-4112-9175-4ffca7691bf8")!
            ]
        )
    }

}
