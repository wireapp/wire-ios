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

import Foundation
import Testing
import WireFoundationSupport
@testable import WireCallingDomain
@testable import WireCallingDomainSupport

@Suite("FetchOngoingMeetingsUseCase Tests")
struct FetchOngoingMeetingsUseCaseTests {

    private let repository = MockMeetingsRepositoryProtocol()
    private let mockDateProvider = CurrentDateProvidingMock()

    init() throws {
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-10-27T13:59:59Z")
    }

    @Test("invoke fetches ongoing meetings from repository")
    func invokeFetchesMeetings() {
        // Given
        let meeting1 = Meeting.fixture(title: "Meeting 1", start: mockDateProvider.now)
        let meeting2 = Meeting.fixture(title: "Meeting 2", start: mockDateProvider.now)
        repository.fetchOngoingMeetingsAt_MockValue = [meeting1, meeting2]

        let useCase = FetchOngoingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = useCase.invoke()

        // Then
        #expect(result.count == 2)
        #expect(result.contains { $0.title == "Meeting 1" })
        #expect(result.contains { $0.title == "Meeting 2" })
    }

    @Test("invoke returns empty array when no ongoing meetings")
    func invoke_WithNoMeetings() {
        // Given
        repository.fetchOngoingMeetingsAt_MockValue = []

        let useCase = FetchOngoingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = useCase.invoke()

        // Then
        #expect(result.isEmpty)
    }

}
