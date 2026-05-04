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

import Foundation
package import SwiftUI
import WireDesign

package struct AllMeetingsView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.List.Actions

    @ObservedObject private var viewModel: AllMeetingsViewModel

    package init(viewModel: AllMeetingsViewModel) {
        self.viewModel = viewModel
    }

    package var body: some View {
        MeetingsView(viewModel: viewModel.meetingsViewModel)
            .navigationTitle(L10n.Localizable.WireMeetings.List.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.createInstantMeetingTapped()
                        } label: {
                            Label(Strings.meetNow, systemImage: "chevron.forward")
                        }

                        Button {
                            viewModel.scheduleMeetingTapped()
                        } label: {
                            Label(Strings.scheduleMeeting, systemImage: "chevron.forward")
                        }
                    } label: {
                        Image(.videoCall)
                            .renderingMode(.template)
                    }
                    .accessibilityIdentifier("scheduleMeetingBarButton")
                    .accessibilityLabel(Text(L10n.Accessibility.WireMeetings.VideoButton.description))
                }
            }
            .toolbarBackground(ColorTheme.Backgrounds.surface.color, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $viewModel.isCreateInstantMeetingPresented) {
                CreateInstantMeetingView(viewModel: viewModel.makeCreateInstantMeetingViewModel())
            }
            .sheet(isPresented: $viewModel.isScheduleMeetingPresented) {
                ScheduleMeetingView(viewModel: viewModel.makeScheduleMeetingViewModel())
            }
    }
}
