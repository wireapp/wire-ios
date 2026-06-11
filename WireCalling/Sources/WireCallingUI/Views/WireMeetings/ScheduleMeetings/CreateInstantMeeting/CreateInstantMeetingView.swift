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
import WireDesign
import WireReusableUIComponents

struct CreateInstantMeetingView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.Schedule

    @Environment(\.dismiss) private var dismiss
    @State private(set) var viewModel: CreateInstantMeetingViewModel

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                participantsSection
            }
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .background(ColorTheme.Backgrounds.background.color)
            .navigationTitle(Strings.Now.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toolbarBackground(ColorTheme.Backgrounds.background.color, for: .navigationBar)
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(Strings.Cancel.button) {
                dismiss()
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(Strings.Start.button) {
                viewModel.createInstantMeeting()
            }
            .disabled(!viewModel.isNextButtonEnabled)
        }
    }

    private var titleSection: some View {
        Section {
            TextField(
                Strings.SetupTitle.header,
                text: $viewModel.meetingTitle,
                prompt: Text(Strings.SetupTitle.placeholder)
            )
        }
        .textCase(nil)
    }

    private var participantsSection: some View {
        Section {
            TextField(
                Strings.SetupParticipants.header,
                text: $viewModel.participants,
                prompt: Text(Strings.SetupParticipants.placeholder)
            )
        }
        .textCase(nil)
    }

}

// MARK: - Preview

#Preview {
    CreateInstantMeetingView(viewModel: CreateInstantMeetingViewModel())
}
