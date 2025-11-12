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
            Picker("", selection: $viewModel.selectedTab) {
                ForEach(MeetingsViewModel.Tab.allCases, id: \.self) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .accessibilityIdentifier("meetingsListPicker")

            content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ColorTheme.Backgrounds.surface.color)
        .onAppear {
            viewModel.loadInitialData()
        }
        .onChange(of: viewModel.selectedTab) { newValue in
            if newValue == .past {
                viewModel.refreshPastMeetings()
            } else {
                viewModel.refreshOngoingMeetings()
            }
        }
    }

    @ViewBuilder private var content: some View {
        if viewModel.selectedTab == .next {
            if viewModel.ongoingMeetings.isEmpty, viewModel.groupedNextMeetings.isEmpty {
                MeetingsEmptyStateView(
                    title: Strings.EmptyState.Next.title,
                    subtitle: Strings.EmptyState.Next.subtitle
                )
            } else {
                nextTabContent
            }
        } else {
            if viewModel.groupedPastMeetings.isEmpty {
                MeetingsEmptyStateView(
                    title: Strings.EmptyState.Past.title,
                    subtitle: Strings.EmptyState.Past.subtitle
                )
            } else {
                pastTabContent
            }
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
                formatDay: viewModel.formatDay(_:),
                formatTime: viewModel.formatTime(_:)
            )

            if viewModel.showMoreButton {
                Button {
                    viewModel.showAll = true
                } label: {
                    Text(Strings.Actions.showAll)
                        .font(.textStyle(.buttonBig))
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

    @ViewBuilder private var pastTabContent: some View {
        List {
            GroupedSections(
                groups: viewModel.groupedPastMeetings,
                formatDay: viewModel.formatDay(_:),
                formatTime: viewModel.formatTime(_:)
            )
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.surface.color)
        .refreshable {
            viewModel.refreshPastMeetings()
        }
    }
}

private func SectionTitle(_ text: String) -> some View {
    Text(text)
        .font(.textStyle(.body2))
        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
        .textCase(nil)
}

private struct GroupedSections: View {
    let groups: [(day: Date, timeSlots: [(time: Date, meetings: [Meeting])])]
    let formatDay: (Date) -> String
    let formatTime: (Date) -> String
    var body: some View {
        ForEach(groups, id: \.day) { dayGroup in
            Section {
                ForEach(dayGroup.timeSlots, id: \.time) { slot in
                    Section {
                        ForEach(slot.meetings, id: \.id) { meeting in
                            MeetingRow(meeting: meeting)
                        }
                    } header: {
                        Text(formatTime(slot.time))
                            .font(.textStyle(.subline1))
                            .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
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

                Image(systemName: "video.fill").font(.system(size: 15))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(meeting.title)
                    .font(.textStyle(.body2))
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                    .lineLimit(2)

                Text("Meeting date")
                    .font(.textStyle(.subline1))
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                HStack(spacing: 6) {
                    Label("Design", systemImage: "person.3.fill")
                        .font(.textStyle(.subline1))
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
        pastMeetingsUseCase: MockFetchPastMeetingsUseCaseProtocol(),
        upcomingMeetingsUseCase: MockFetchUpcomingMeetingsUseCaseProtocol()
    )
    )
}
