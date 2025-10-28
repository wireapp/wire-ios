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

import Foundation
package import SwiftUI
import WireDesign
import WireAccountImageUI

package struct AllMeetingsView: View {
    private typealias Strings = L10n.Localizable.WireMeetings.List.Actions

    @ObservedObject private var viewModel: MeetingsViewModel

    package init(viewModel: MeetingsViewModel) {
        self.viewModel = viewModel
    }

    package var body: some View {
        MeetingsView(viewModel: viewModel)
            .navigationTitle(L10n.Localizable.WireMeetings.List.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let avatarViewModel = viewModel.avatarViewModel {
                    ToolbarItem(placement: .topBarLeading) {
                        makeAccountImageView(with: avatarViewModel)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.meetNowTapped()
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
                }
            }
            .toolbarBackground(ColorTheme.Backgrounds.surface.color, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func makeAccountImageView(with avatarViewModel: AccountAvatarViewModel) -> some View {
        Button {
            avatarViewModel.handleAvatarTap()
        } label: {
            AccountImageViewRepresentable(
                source: convertAccountImageSource(avatarViewModel.accountImageSource),
                availability: convertAvailability(avatarViewModel.availability),
                showNotificationsBadge: avatarViewModel.showNotificationsBadge
            )
            .frame(width: 28, height: 28)
            .accountImageBorderWidth(1)
            .accountImageViewBorderColor(ColorTheme.Strokes.outline)
            .availabilityIndicatorAvailableColor(ColorTheme.Base.positive)
            .availabilityIndicatorBusyColor(ColorTheme.Base.warning)
            .availabilityIndicatorAwayColor(ColorTheme.Base.error)
            .availabilityIndicatorBackgroundViewColor(ColorTheme.Backgrounds.surface)
        }
        .accessibilityLabel("Account Profile")
        //.accessibilityHint(L10n.Accessibility.ConversationsList.AccountButton.hint)
        .accessibilityIdentifier("account_profile_image_view")
    }

    private func convertAccountImageSource(_ source: AccountImageSource) -> WireAccountImageUI.AccountImageSource {
        switch source {
        case .image(let image):
            return .image(image)
        case .text(let initials):
            return .text(initials)
        }
    }

    private func convertAvailability(_ availability: Availability?) -> WireAccountImageUI.Availability? {
        guard let availability = availability else { return nil }

        switch availability {
        case .available:
            return .available
        case .away:
            return .away
        case .busy:
            return .busy
        case .none:
            return .none
        }
    }

}
