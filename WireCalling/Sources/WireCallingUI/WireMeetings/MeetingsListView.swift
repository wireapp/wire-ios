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

public import SwiftUI
import WireDesign

// TODO: remove public
public struct MeetingsListView: View {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    @ObservedObject private var viewModel: MeetingsListViewModel

    public init(viewModel: MeetingsListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack {
            Picker("", selection: Binding(
                get: { viewModel.selectedTab.rawValue },
                set: { viewModel.selectedTab = MeetingsListViewModel.Tab(rawValue: $0) ?? .next }
            )) {
                ForEach(MeetingsListViewModel.Tab.allCases, id: \.rawValue) { tab in
                    Text(tab.title).tag(tab.rawValue)
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
    }

    @ViewBuilder private var content: some View {
        List {
            if viewModel.selectedTab == .next {
                if !viewModel.ongoingMeetings.isEmpty {
                    Section {
                        ForEach(viewModel.groupedOngoing.first?.timeSlots.first?.meetings ?? [], id: \.id) { meeting in
                            MeetingRow(meeting: meeting)
                        }
                    } header: {
                        Text(Strings.Header.ongoing)
                            .font(.textStyle(.body2))
                            .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                            .textCase(nil)
                    }
                }
                // TODO: clean up
                ForEach(viewModel.groupedNext, id: \.day) { dayGroup in
                    Section {
                        ForEach(dayGroup.timeSlots, id: \.time) { timeSlot in
                            Section {
                                ForEach(timeSlot.meetings, id: \.id) { meeting in
                                    MeetingRow(meeting: meeting)
                                }
                            } header: {
                                Text(viewModel.formatTime(timeSlot.time))
                                    .font(.textStyle(.subline1))
                                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                            }
                        }
                    } header: {
                        Text(viewModel.formatDay(dayGroup.day))
                            .font(.textStyle(.body2))
                            .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                            .textCase(nil)
                    }
                }

                if viewModel.hasMoreNext {
                    Button {
                        viewModel.showAllNext = true
                    } label: {
                        Text(Strings.Actions.showAll)
                            .font(.textStyle(.buttonBig))
                    }
                    .wireButtonStyle(.secondary)
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(viewModel.groupedPast, id: \.day) { dayGroup in
                    Section {
                        ForEach(dayGroup.timeSlots, id: \.time) { timeSlot in
                            Section {
                                ForEach(timeSlot.meetings, id: \.id) { meeting in
                                    MeetingRow(meeting: meeting)
                                }
                            } header: {
                                Text(viewModel.formatTime(timeSlot.time))
                                    .font(.textStyle(.subline1))
                                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                            }
                        }
                    } header: {
                        Text(viewModel.formatDay(dayGroup.day))
                            .font(.textStyle(.body2))
                            .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                            .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.surface.color)
    }
}

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

                Text(
                    "\(DateFormatter.timeHeader.string(from: meeting.start)) – \(DateFormatter.timeHeader.string(from: meeting.end))"
                )
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

// #Preview {
//    MeetingsListView(viewModel: MeetingsListViewModel(account: AccountUIViewModel(avatarSource: .text("AN"), availability: nil, action: {})))
// }
