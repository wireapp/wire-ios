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
    private let meetingsSource: @Sendable () -> [Meeting]

    package init(
        meetingsAPI: any MeetingsAPI,
        meetings: @Sendable @escaping () -> [Meeting]
    ) {
        self.meetingsAPI = meetingsAPI
        self.meetingsSource = meetings
    }

    package func fetchMeetingsStarting(after date: Date, offset: Int, limit: Int) -> [Meeting] {
        let allFuture = meetingsSource()
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

    package func hasUpcomingMeetings(after date: Date) -> Bool {
        meetingsSource().contains { $0.start > date }
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
        return response.toDomainMeeting()
    }

}

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

package extension MeetingRepository {

    static func demo(
        meetingsAPI: any MeetingsAPI
    ) -> MeetingRepository {
        let cal = Calendar.current
        let now = Date()
        func day(_ offset: Int, hour: Int, min: Int = 0) -> Date {
            cal.date(
                bySettingHour: hour,
                minute: min,
                second: 0,
                of: cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: now))!
            )!
        }
        let meetings: [Meeting] = [
            // YESTERDAY
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "iOS Playtest - develop build",
                start: day(-1, hour: 8, min: 0),
                end: day(-1, hour: 8, min: 30),
                members: [Member(name: "User1")]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "Sprint Review (all teams)",
                start: day(-1, hour: 16, min: 0),
                end: day(-1, hour: 16, min: 30),
                members: [Member(name: "User1")]
            ),

            // TODAY — several at 7:00 AM for time grouping
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "Candidate interview",
                start: day(0, hour: 16, min: 0),
                end: day(0, hour: 16, min: 45),
                members: [Member(name: "User1")]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "Standup",
                start: day(0, hour: 7, min: 0),
                end: day(0, hour: 7, min: 30),
                members: [Member(name: "User1")]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "iOS team update",
                start: day(0, hour: 7, min: 0),
                end: day(0, hour: 7, min: 20),
                members: [Member(name: "User1")]
            ),

            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "Design review",
                start: day(0, hour: 17),
                end: day(0, hour: 18),
                members: [Member(name: "User1")]
            ),

            // TOMORROW — again two meetings at 7:00 AM to group
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "Sprint planning",
                start: day(1, hour: 7),
                end: day(1, hour: 8),
                members: [Member(name: "User1")]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "Daily sync",
                start: day(1, hour: 7),
                end: day(1, hour: 7, min: 20),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "Architecture Forum",
                start: day(1, hour: 13),
                end: day(1, hour: 14),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(3, hour: 11),
                end: day(3, hour: 12),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3"),
                    Member(name: "User4")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(3, hour: 12),
                end: day(3, hour: 13),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3"),
                    Member(name: "User4"),
                    Member(name: "User5"),
                    Member(name: "User6")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(3, hour: 14),
                end: day(3, hour: 15),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3"),
                    Member(name: "User4"),
                    Member(name: "User5"),
                    Member(name: "User6"),
                    Member(name: "User7"),
                    Member(name: "User8"),
                    Member(name: "User9")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(3, hour: 16),
                end: day(3, hour: 17),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(4, hour: 14),
                end: day(4, hour: 15),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3"),
                    Member(name: "User4")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(4, hour: 16),
                end: day(4, hour: 17),
                members: [
                    Member(name: "User1")
                ]
            ),

            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(5, hour: 12),
                end: day(5, hour: 13),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(5, hour: 14),
                end: day(5, hour: 15),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(5, hour: 16),
                end: day(5, hour: 17),
                members: [
                    Member(name: "User1")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(6, hour: 14),
                end: day(6, hour: 15),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3"),
                    Member(name: "User4")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(6, hour: 16),
                end: day(6, hour: 17),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(7, hour: 12),
                end: day(7, hour: 13),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3"),
                    Member(name: "User4"),
                    Member(name: "User5"),
                    Member(name: "User6"),
                    Member(name: "User7"),
                    Member(name: "User8"),
                    Member(name: "User9")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(7, hour: 14),
                end: day(7, hour: 15),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(7, hour: 16),
                end: day(7, hour: 17),
                members: [
                    Member(name: "User1")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(8, hour: 14),
                end: day(8, hour: 15),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3"),
                    Member(name: "User4"),
                    Member(name: "User5"),
                    Member(name: "User6"),
                    Member(name: "User7"),
                    Member(name: "User8"),
                    Member(name: "User9")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(8, hour: 16),
                end: day(8, hour: 17),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(9, hour: 12),
                end: day(9, hour: 13),
                members: [
                    Member(name: "User1")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(9, hour: 14),
                end: day(9, hour: 15),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3"),
                    Member(name: "User4"),
                    Member(name: "User5"),
                    Member(name: "User6"),
                    Member(name: "User7"),
                    Member(name: "User8"),
                    Member(name: "User9")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(9, hour: 16),
                end: day(9, hour: 17),
                members: [
                    Member(name: "User1")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(10, hour: 14),
                end: day(10, hour: 15),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(10, hour: 16),
                end: day(10, hour: 17),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(11, hour: 12),
                end: day(11, hour: 13),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(11, hour: 14),
                end: day(11, hour: 15),
                members: [
                    Member(name: "User1")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(11, hour: 16),
                end: day(11, hour: 17),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(12, hour: 14),
                end: day(12, hour: 15),
                members: [
                    Member(name: "User1")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(12, hour: 16),
                end: day(12, hour: 17),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3"),
                    Member(name: "User4"),
                    Member(name: "User5"),
                    Member(name: "User6"),
                    Member(name: "User7"),
                    Member(name: "User8"),
                    Member(name: "User9")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(13, hour: 12),
                end: day(13, hour: 13),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(13, hour: 14),
                end: day(13, hour: 15),
                members: [
                    Member(name: "User1")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(13, hour: 16),
                end: day(13, hour: 17),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(14, hour: 14),
                end: day(14, hour: 15),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(14, hour: 16),
                end: day(14, hour: 17),
                members: [
                    Member(name: "User1")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(15, hour: 12),
                end: day(15, hour: 13),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3"),
                    Member(name: "User4"),
                    Member(name: "User5"),
                    Member(name: "User6"),
                    Member(name: "User7"),
                    Member(name: "User8"),
                    Member(name: "User9")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(15, hour: 14),
                end: day(15, hour: 15),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(15, hour: 16),
                end: day(15, hour: 17),
                members: [
                    Member(name: "User1")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(16, hour: 14),
                end: day(16, hour: 15),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2")
                ]
            ),
            Meeting(
                id: QualifiedID(id: UUID(), domain: ""),
                title: "All hands",
                start: day(16, hour: 16),
                end: day(16, hour: 17),
                members: [
                    Member(name: "User1"),
                    Member(name: "User2"),
                    Member(name: "User3"),
                    Member(name: "User4"),
                    Member(name: "User5"),
                    Member(name: "User6"),
                    Member(name: "User7"),
                    Member(name: "User8"),
                    Member(name: "User9")
                ]
            )
        ]

        return MeetingRepository(
            meetingsAPI: meetingsAPI,
            meetings: { meetings }
        )
    }
}

private extension Meeting {

    init(
        id: QualifiedID,
        title: String,
        start: Date,
        end: Date,
        members: [Member]
    ) {
        self.init(
            id: id,
            title: title,
            start: start,
            end: end,
            recurrence: nil,
            members: members,
            conversationID: QualifiedID(id: UUID(), domain: "")
        )
    }

}

private extension Member {

    init(name: String) {
        self.init(
            qualifiedID: .init(id: UUID(), domain: ""),
            name: name,
            handle: name
                .lowercased()
                .replacingOccurrences(of: " ", with: "")
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
