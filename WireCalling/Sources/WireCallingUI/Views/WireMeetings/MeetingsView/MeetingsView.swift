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
import WireCallingDomainSupport
import WireDesign

struct MeetingsView: View {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    @ObservedObject private var viewModel: MeetingsViewModel

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
            if viewModel.ongoingMeetings.isEmpty, viewModel.groupedNextMeetings.isEmpty {
                MeetingsEmptyStateView(
                    title: Strings.EmptyState.Next.title,
                    subtitle: Strings.EmptyState.Next.subtitle
                )
            } else {
                nextTabContent
            }
    }

    @ViewBuilder private var nextTabContent: some View {
        List {
            if !viewModel.ongoingMeetings.isEmpty {
                Section {
                    ForEach(viewModel.ongoingMeetings, id: \.id) { meeting in
                        MeetingRow(meeting: meeting)
                    }
                } header: {
                    SectionTitle(Strings.Header.ongoing)
                }
            }
            GroupedSections(
                groups: viewModel.groupedNextMeetings,
                formatDay: viewModel.formatDay(_:)
            )

            if viewModel.showMoreButton {
                Button {
                    viewModel.showAll = true
                } label: {
                    Text(Strings.Actions.showAll)
                        .font(for: .buttonBig)
                }
                .wireButtonStyle(.secondary)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.surface.color)
        .refreshable {
            viewModel.refreshOngoingMeetings()
            viewModel.showAll = false
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
    let groups: [(day: Date, timeSlots: [(time: Date, meetings: [Meeting])])]
    let formatDay: (Date) -> String
    var body: some View {
        ForEach(groups, id: \.day) { dayGroup in
            Section {
                ForEach(dayGroup.timeSlots, id: \.time) { slot in
                    Section {
                        ForEach(slot.meetings, id: \.id) { meeting in
                            MeetingRow(meeting: meeting)
                        }
                    }
                }
            } header: {
                SectionTitle(formatDay(dayGroup.day))
            }
        }
    }
}

// MARK: - Row

private struct MeetingRow: View {
    let meeting: Meeting
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(ColorTheme.Backgrounds.surface.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(ColorTheme.Strokes.outline.color, lineWidth: 1)
                    )
                    .frame(width: 31, height: 31)

                Image(systemName: "calendar").font(.system(size: 15))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(meeting.title)
                    .font(for: .body2)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                    .lineLimit(2)

                Text("Meeting date")
                    .font(for: .subline1)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                HStack(spacing: 6) {
                    Label("Design", systemImage: "person.3.fill")
                        .font(for: .subline1)
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                }
                .padding(.top, 2)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .foregroundStyle(ColorTheme.Buttons.Secondary.onEnabled.color)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 6)
    }
}

#Preview {
    MeetingsView(viewModel: MeetingsViewModel(
        repository: MockMeetingsRepositoryProtocol(),
        currentDateProvider: .system,
        formatter: MeetingsFormatter(),
        upcomingMeetingsUseCase: MockFetchUpcomingMeetingsUseCaseProtocol()
    )
    )
}
