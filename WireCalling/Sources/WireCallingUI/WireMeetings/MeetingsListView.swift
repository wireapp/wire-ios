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

public struct MeetingsListView: View {

    @ObservedObject private var viewModel: MeetingsListViewModel

    public init(viewModel: MeetingsListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: Binding(
                get: { viewModel.selectedTab.rawValue },
                set: { viewModel.selectedTab = MeetingsListViewModel.Tab(rawValue: $0) ?? .upcoming }
            )) {
                ForEach(MeetingsListViewModel.Tab.allCases, id: \.rawValue) { tab in
                    Text(tab.title).tag(tab.rawValue)
                }
            }
            .pickerStyle(.segmented)
            //.padding(.horizontal)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .accessibilityHint("Switch between upcoming and past meetings")

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(Color(uiColor: .systemBackground))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.selectedTab {
        case .upcoming:
            Text("Upcoming meetings").frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
        case .past:
            Text("Past meetings").frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
        }
    }

}

#Preview {
    MeetingsListView(viewModel: MeetingsListViewModel())
}
