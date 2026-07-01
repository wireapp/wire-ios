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
        .onAppear {
            viewModel.loadInitialData()
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
                onDelete: { _ in
                    // TODO: [WPB-25514] Implement UI
                }
            )

            if viewModel.hasMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .onAppear { viewModel.loadMoreIfNeeded() }
            }
        }
        .listStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.surface.color)
        .refreshable {
            viewModel.loadInitialData()
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
            upcomingMeetingsUseCase: PreviewFetchUpcomingMeetingsUseCase()
        )
    )
}

private struct PreviewFetchUpcomingMeetingsUseCase: FetchUpcomingMeetingsUseCaseProtocol {

    var meetings = [Meeting]()

    func invoke(pageSize: Int, offset: Int) -> PaginatedMeetings {
        .init(meetings: meetings, hasMore: false, nextOffset: 0)
    }

}
