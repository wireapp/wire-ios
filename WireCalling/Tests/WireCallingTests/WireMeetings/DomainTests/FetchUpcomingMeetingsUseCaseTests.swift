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

import Foundation
import Testing
import WireFoundationSupport
@testable import WireCallingDomain
@testable import WireCallingDomainSupport

@Suite("FetchUpcomingMeetingsUseCase Tests")
struct FetchUpcomingMeetingsUseCaseTests {

    private let repository = MockMeetingsRepositoryProtocol()
    private let calendar = Calendar.current

    @Test("invoke fetches upcoming meetings from repository")
    func invokeFetchesMeetings() throws {
        // Given
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-10-27T13:59:59Z")

        let meeting1 = Meeting.fixture(title: "Meeting 1", start: mockDateProvider.now.addingTimeInterval(3600))
        let meeting2 = Meeting.fixture(title: "Meeting 2", start: mockDateProvider.now.addingTimeInterval(7200))
        repository.fetchMeetingsStartingAfterOffsetLimit_MockValue = [meeting1, meeting2]

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = useCase.invoke(limitToTwoDays: false, pageSize: 10, offset: 0)

        // Then
        let meetings = result.groups.flatMap { $0.timeSlots.flatMap(\.meetings) }
        #expect(meetings.count == 2)
        #expect(meetings.contains { $0.title == "Meeting 1" })
        #expect(meetings.contains { $0.title == "Meeting 2" })
    }

    @Test("invoke returns empty result when no upcoming meetings")
    func invoke_WithNoMeetings() throws {
        // Given
        repository.fetchMeetingsStartingAfterOffsetLimit_MockValue = []
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-10-27T13:59:59Z")

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = useCase.invoke(limitToTwoDays: false, pageSize: 10, offset: 0)

        // Then
        #expect(result.groups.isEmpty)
        #expect(!result.hasMore)
    }

    @Test("invoke returns hasMore true when more meetings exist than pageSize")
    func invoke_WithMoreMeetingsThanPageSize() throws {
        // Given
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-10-27T13:59:59Z")

        let meetings = (0 ... 10).map { index in
            Meeting.fixture(
                title: "Meeting \(index)",
                start: mockDateProvider.now.addingTimeInterval(TimeInterval(index * 3600))
            )
        }
        repository.fetchMeetingsStartingAfterOffsetLimit_MockValue = meetings

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = useCase.invoke(limitToTwoDays: false, pageSize: 10, offset: 0)

        // Then
        #expect(result.hasMore)
        let returnedMeetings = result.groups.flatMap { $0.timeSlots.flatMap(\.meetings) }
        #expect(returnedMeetings.count == 10)
    }

    @Test("invoke returns hasMore false when meetings count equals pageSize")
    func invoke_WithExactlyPageSizeMeetings() throws {
        // Given
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-10-27T13:59:59Z")

        let meetings = (0 ..< 10).map { index in
            Meeting.fixture(
                title: "Meeting \(index)",
                start: mockDateProvider.now.addingTimeInterval(TimeInterval(index * 3600))
            )
        }
        repository.fetchMeetingsStartingAfterOffsetLimit_MockValue = meetings

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = useCase.invoke(limitToTwoDays: false, pageSize: 10, offset: 0)

        // Then
        #expect(!result.hasMore)
        let returnedMeetings = result.groups.flatMap { $0.timeSlots.flatMap(\.meetings) }
        #expect(returnedMeetings.count == 10)
    }

    @Test("invoke filters meetings beyond two days when limitToTwoDays is true")
    func invoke_WithLimitToTwoDays() {
        // Given
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 0

        guard let currentDate = calendar.date(from: components),
              let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: currentDate)),
              let afterTomorrowStart = calendar.date(
                  byAdding: .day,
                  value: 2,
                  to: calendar.startOfDay(for: currentDate)
              )
        else {
            return
        }

        let todayMeeting = Meeting.fixture(title: "Today Meeting", start: currentDate.addingTimeInterval(3600))
        let tomorrowMeeting = Meeting.fixture(title: "Tomorrow Meeting", start: tomorrowStart.addingTimeInterval(3600))
        let afterTomorrowMeeting = Meeting.fixture(
            title: "After Tomorrow Meeting",
            start: afterTomorrowStart.addingTimeInterval(3600)
        )

        repository.fetchMeetingsStartingAfterOffsetLimit_MockValue = [
            todayMeeting,
            tomorrowMeeting,
            afterTomorrowMeeting
        ]
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = currentDate

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = useCase.invoke(limitToTwoDays: true, pageSize: 10, offset: 0)

        // Then
        let meetings = result.groups.flatMap { $0.timeSlots.flatMap(\.meetings) }
        #expect(meetings.count == 2)
        #expect(meetings.contains { $0.title == "Today Meeting" })
        #expect(meetings.contains { $0.title == "Tomorrow Meeting" })
        #expect(!meetings.contains { $0.title == "After Tomorrow Meeting" })
    }

    @Test("invoke groups meetings by hour")
    func invoke_GroupsByHour() {
        // Given
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 0

        guard let currentDate = calendar.date(from: components) else {
            return
        }

        let meeting1 = Meeting.fixture(title: "Meeting 1", start: currentDate.addingTimeInterval(3600))
        let meeting2 = Meeting.fixture(title: "Meeting 2", start: currentDate.addingTimeInterval(3900))
        let meeting3 = Meeting.fixture(title: "Meeting 3", start: currentDate.addingTimeInterval(7200))

        repository.fetchMeetingsStartingAfterOffsetLimit_MockValue = [meeting1, meeting2, meeting3]
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = currentDate

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = useCase.invoke(limitToTwoDays: false, pageSize: 10, offset: 0)

        // Then
        #expect(!result.groups.isEmpty)
        if let dayGroup = result.groups.first {
            #expect(dayGroup.timeSlots.count >= 1)
        }
    }

}
