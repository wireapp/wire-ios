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

import SwiftUI
import WireCallingDomain
import WireDesign
import WireFoundation

struct MeetingsView: View {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    @State private var viewModel: MeetingsViewModel

    init(viewModel: MeetingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ColorTheme.Backgrounds.surface.color)
        .task {
            await viewModel.loadInitialData()
        }
    }

    @ViewBuilder private var content: some View {

        if viewModel.groupedUpcomingMeetings.isEmpty {
            MeetingsEmptyStateView(
                title: Strings.EmptyState.Next.title,
                subtitle: Strings.EmptyState.Next.subtitle
            )
        } else {
            meetingsList
        }
    }

    @ViewBuilder private var meetingsList: some View {
        List {
            GroupedSections(
                groups: viewModel.groupedUpcomingMeetings,
                formatDay: viewModel.formatDay(_:),
                formatTimeRange: viewModel.formatTimeRange(for:),
                onEdit: { _ in
                    // TODO: [WPB-25501] Implement UI
                },
                onDelete: { meeting in
                    Task { try? await viewModel.deleteMeeting(meeting) }
                }
            )

            if viewModel.hasMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .task { await viewModel.loadMoreIfNeeded() }
            }
        }
        .listStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.surface.color)
        .refreshable {
            await viewModel.loadInitialData()
        }
    }

}

@ViewBuilder
@MainActor
private func SectionTitle(_ text: String) -> some View {
    Text(text)
        .font(for: .body2)
        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
        .textCase(nil)
}

private struct GroupedSections: View {
    let groups: [(day: Date, meetings: [Meeting])]
    let formatDay: (Date) -> String
    let formatTimeRange: (Meeting) -> String
    let onEdit: (Meeting) -> Void
    let onDelete: (Meeting) -> Void

    var body: some View {
        ForEach(groups, id: \.day) { dayGroup in
            Section {
                ForEach(dayGroup.meetings, id: \.id) { meeting in
                    MeetingRow(
                        meeting: meeting,
                        formatTimeRange: formatTimeRange,
                        onEdit: { onEdit(meeting) },
                        onDelete: { onDelete(meeting) }
                    )
                }
            } header: {
                SectionTitle(formatDay(dayGroup.day))
            }
        }
    }
}

#Preview("empty") {
    MeetingsView(
        viewModel: MeetingsViewModel(
            currentDateProvider: .system,
            formatter: MeetingsFormatter(),
            upcomingMeetingsUseCase: PreviewFetchUpcomingMeetingsUseCase(),
            deleteMeetingUseCase: PreviewDeleteMeetingUseCase()
        )
    )
}

#Preview("non-empty") {
    MeetingsView(
        viewModel: MeetingsViewModel(
            currentDateProvider: .system,
            formatter: MeetingsFormatter(),
            upcomingMeetingsUseCase: PreviewFetchUpcomingMeetingsUseCase(
                meetings: previewMeetings()
            ),
            deleteMeetingUseCase: PreviewDeleteMeetingUseCase()
        )
    )
}

private struct PreviewFetchUpcomingMeetingsUseCase: FetchUpcomingMeetingsUseCaseProtocol {

    var meetings = [Meeting]()

    func invoke(pageSize: Int, offset: Int) async throws -> PaginatedMeetings {
        .init(meetings: meetings, hasMore: false, nextOffset: 0)
    }

}

private struct PreviewDeleteMeetingUseCase: DeleteMeetingUseCaseProtocol {

    func invoke(meetingID: QualifiedID) async throws {}

}

private func previewMeetings() -> [Meeting] {
    let calendar = Calendar.current
    let now = Date()

    func day(_ offset: Int, hour: Int, minute: Int = 0) -> Date {
        calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!
        )!
    }

    func member(_ name: String) -> MeetingMember {
        MeetingMember(
            qualifiedID: QualifiedID(id: UUID(), domain: ""),
            name: name,
            handle: name.lowercased().replacingOccurrences(of: " ", with: "")
        )
    }

    func meeting(_ title: String, start: Date, end: Date, members: [MeetingMember]) -> Meeting {
        Meeting(
            id: QualifiedID(id: UUID(), domain: ""),
            title: title,
            start: start,
            end: end,
            recurrence: nil,
            members: members,
            conversationID: QualifiedID(id: UUID(), domain: ""),
            creatorID: QualifiedID(id: UUID(), domain: "")
        )
    }

    return [
        // TODAY — two meetings at the same time to exercise time grouping
        meeting(
            "Standup",
            start: day(0, hour: 7),
            end: day(0, hour: 7, minute: 30),
            members: []
        ),
        meeting(
            "iOS team update",
            start: day(0, hour: 7),
            end: day(0, hour: 7, minute: 20),
            members: [member("User1")]
        ),
        meeting(
            "Candidate interview",
            start: day(0, hour: 16),
            end: day(0, hour: 16, minute: 45),
            members: [member("User1")]
        ),
        meeting(
            "Design review",
            start: day(0, hour: 17),
            end: day(0, hour: 18),
            members: [member("User1")]
        ),

        // TOMORROW
        meeting(
            "Sprint planning",
            start: day(1, hour: 7),
            end: day(1, hour: 8),
            members: [member("User1")]
        ),
        meeting(
            "Daily sync",
            start: day(1, hour: 7),
            end: day(1, hour: 7, minute: 20),
            members: [member("User1"), member("User2")]
        ),
        meeting(
            "Architecture Forum",
            start: day(1, hour: 13),
            end: day(1, hour: 14),
            members: [member("User1"), member("User2"), member("User3")]
        ),

        // NEXT WEEK
        meeting(
            "Sprint Review (all teams)",
            start: day(7, hour: 16),
            end: day(7, hour: 16, minute: 30),
            members: [member("User1")]
        )
    ]
}
