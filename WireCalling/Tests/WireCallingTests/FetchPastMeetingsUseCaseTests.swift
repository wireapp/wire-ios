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

@Suite("FetchPastMeetingsUseCase Tests")
struct FetchPastMeetingsUseCaseTests {

    private let repository = MockMeetingsRepositoryProtocol()
    private let calendar = Calendar.current

    @Test("invoke fetches and filters past meetings from yesterday onwards")
    func invokeFetchesPastMeetings() {
        // Given
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 0

        guard let currentDate = calendar.date(from: components),
              let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: currentDate)),
              let yesterdayMeeting = calendar.date(byAdding: .hour, value: 2, to: yesterdayStart),
              let todayMeeting = calendar.date(byAdding: .hour, value: -2, to: currentDate)
        else {
            return
        }
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = currentDate

        let meeting1 = Meeting.fixture(title: "Yesterday Meeting", start: yesterdayMeeting)
        let meeting2 = Meeting.fixture(title: "Today Past Meeting", start: todayMeeting)

        repository.fetchPastMeetingsUntil_MockValue = [meeting1, meeting2]

        let useCase = FetchPastMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = useCase.invoke()

        // Then
        #expect(result.count == 2)
    }

    @Test("invoke filters out meetings before yesterday")
    func invoke_FiltersOldMeetings() {
        // Given
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 0

        guard let currentDate = calendar.date(from: components),
              let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: currentDate)),
              let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: currentDate)),
              let yesterdayMeeting = calendar.date(byAdding: .hour, value: 2, to: yesterdayStart)
        else {
            return
        }
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = currentDate

        let oldMeeting = Meeting.fixture(title: "Old Meeting", start: twoDaysAgo)
        let recentMeeting = Meeting.fixture(title: "Yesterday Meeting", start: yesterdayMeeting)

        repository.fetchPastMeetingsUntil_MockValue = [oldMeeting, recentMeeting]

        let useCase = FetchPastMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = useCase.invoke()

        // Then
        let meetings = result.flatMap { $0.timeSlots.flatMap(\.meetings) }
        #expect(meetings.count == 1)
        #expect(meetings[0].title == "Yesterday Meeting")
    }

    @Test("invoke returns empty array when no past meetings in range")
    func invoke_WithNoPastMeetings() throws {
        // Given
        repository.fetchPastMeetingsUntil_MockValue = []
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-10-27T13:59:59Z")

        let useCase = FetchPastMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = useCase.invoke()

        // Then
        #expect(result.isEmpty)
    }

    @Test("invoke groups meetings by hour")
    func invokeGroupsByHour() {
        // Given
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = 10
        components.minute = 0

        guard let currentDate = calendar.date(from: components),
              let meeting1Time = calendar.date(byAdding: .hour, value: -3, to: currentDate),
              let meeting2Time = calendar.date(byAdding: .minute, value: -180 + 15, to: currentDate),
              let meeting3Time = calendar.date(byAdding: .hour, value: -1, to: currentDate)
        else {
            return
        }
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = currentDate

        let meeting1 = Meeting.fixture(title: "Meeting 1", start: meeting1Time)
        let meeting2 = Meeting.fixture(title: "Meeting 2", start: meeting2Time)
        let meeting3 = Meeting.fixture(title: "Meeting 3", start: meeting3Time)

        repository.fetchPastMeetingsUntil_MockValue = [meeting1, meeting2, meeting3]

        let useCase = FetchPastMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = useCase.invoke()

        // Then
        #expect(!result.isEmpty)
        if let dayGroup = result.first {
            #expect(dayGroup.timeSlots.count >= 1)
        }
    }

}
