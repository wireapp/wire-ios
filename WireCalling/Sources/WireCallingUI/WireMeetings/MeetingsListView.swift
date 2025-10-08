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

public struct MeetingsListView: View {

    @ObservedObject private var viewModel: MeetingsListViewModel

    public init(viewModel: MeetingsListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.hasMeetingsForSelectedTab {
                VStack(spacing: 0) {
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
            } else {
                MeetingsEmptyStateView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ColorTheme.Backgrounds.surface.color)
    }

    @ViewBuilder private var content: some View {
        switch viewModel.selectedTab {
        case .next:
            MeetingsDaySectionedList(
                sections: viewModel.upcomingDaySections,
                footer: viewModel.shouldShowAllOnUpcoming ? AnyView(ShowAllFooter { viewModel.onTapShowAll() }) : nil
            )
        case .past:
            MeetingsDaySectionedList(
                sections: viewModel.pastDaySections,
                footer: nil
            )
        }
    }

}

private struct MeetingRow: View {
    let meeting: Meeting
    private let timeFmt: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "h:mm a"
        return df
    }()

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

                Text("\(timeFmt.string(from: meeting.start)) – \(timeFmt.string(from: meeting.end))")
                    .font(.textStyle(.subline1))
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                HStack(spacing: 6) {
                        Label(meeting.team, systemImage: "person.3.fill")
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

private struct MeetingsDaySectionedList: View {
    let sections: [MeetingDaySection]
    let footer: AnyView?

    var body: some View {
        List {
            ForEach(sections) { day in
                if !day.timeGroups.isEmpty {
                    Section(header: Text(day.title)
                        .font(.textStyle(.body2))
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                        .textCase(nil)
                    ) {
                        ForEach(day.timeGroups) { group in
                            Text(group.timeLabel)
                                .font(.textStyle(.subline1))
                                .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                                .padding(.top, 4)
                                .listRowBackground(Color.clear)

                            ForEach(group.items) { meeting in
                                MeetingRow(meeting: meeting)
                                    .contentShape(Rectangle())
                                    .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }

        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.surface.color)
    }
}

private struct ShowAllFooter: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text("Show All").fontWeight(.semibold)
                Spacer()
            }
        }
        .accessibilityIdentifier("showAllButton")
    }
}

#Preview {
    MeetingsListView(viewModel: MeetingsListViewModel(account: AccountUIViewModel(avatarSource: .text("AN"), availability: nil, action: {})))
}
