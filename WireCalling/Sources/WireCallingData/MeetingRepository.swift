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

package import Foundation
package import WireCallingDomain
package import WireNetwork

import WireFoundation

package final class MeetingRepository: MeetingRepositoryProtocol {

    package typealias MeetingRecurrence = WireCallingDomain.MeetingRecurrence

    private let meetingsAPI: any MeetingsAPI
    private let meetingsLocalStore: any MeetingsLocalStoreProtocol

    package init(
        meetingsAPI: any MeetingsAPI,
        meetingsLocalStore: any MeetingsLocalStoreProtocol
    ) {
        self.meetingsAPI = meetingsAPI
        self.meetingsLocalStore = meetingsLocalStore
    }

    package func fetchMeetingsStarting(after date: Date, offset: Int, limit: Int) async throws -> [Meeting] {
        try await refreshStoredMeetings()

        let allFuture = await meetingsLocalStore.storedMeetings()
            .filter { $0.start > date }
            .sorted {
                if $0.start != $1.start {
                    $0.start < $1.start
                } else {
                    $0.title < $1.title
                }
            }
        let start = min(offset, allFuture.count)
        let end = min(offset + limit, allFuture.count)
        return Array(allFuture[start ..< end])
    }

    package func hasUpcomingMeetings(after date: Date) async throws -> Bool {
        try await refreshStoredMeetings()

        return await meetingsLocalStore.storedMeetings().contains { $0.start > date }
    }

    package func createMeeting(
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: MeetingRecurrence?
    ) async throws -> Meeting {
        let response = try await meetingsAPI.createMeeting(
            parameters: CreateMeetingParameters(
                title: title,
                startTime: startTime,
                endTime: endTime,
                recurrence: recurrence?.toNetworkRecurrence()
            )
        )
        let meeting = response.toDomainMeeting()
        await meetingsLocalStore.storeMeeting(meeting)
        return meeting
    }

    /// Refreshes the local store with the latest snapshot of meetings from the backend.
    /// When the backend is unreachable, previously stored meetings are kept and served;
    /// the error is only rethrown if there are no stored meetings to fall back to.
    private func refreshStoredMeetings() async throws {
        do {
            let meetings = try await meetingsAPI.listMeetings().map { $0.toDomainMeeting() }
            await meetingsLocalStore.replaceAllMeetings(with: meetings)
        } catch {
            guard await !meetingsLocalStore.storedMeetings().isEmpty else { throw error }
        }
    }

}

// MARK: - Mapping

private extension MeetingResponse {
    func toDomainMeeting() -> Meeting {
        Meeting(
            id: id,
            title: title,
            start: startTime,
            end: endTime,
            recurrence: recurrence?.toDomainRecurrence(),
            members: [],
            conversationID: conversationID
        )
    }
}

private extension WireNetwork.MeetingRecurrence {
    func toDomainRecurrence() -> WireCallingDomain.MeetingRecurrence {
        let domainFrequency: WireCallingDomain.MeetingRecurrence.Frequency = switch frequency {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
        return MeetingRecurrence(
            frequency: domainFrequency,
            interval: interval ?? 1,
            until: until ?? .distantFuture
        )
    }
}

private extension WireCallingDomain.MeetingRecurrence {
    func toNetworkRecurrence() -> WireNetwork.MeetingRecurrence {
        let networkFrequency: MeetingFrequency = switch frequency {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
        return MeetingRecurrence(
            frequency: networkFrequency,
            interval: interval,
            until: until
        )
    }
}
