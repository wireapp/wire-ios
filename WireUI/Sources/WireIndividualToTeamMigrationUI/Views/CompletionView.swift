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
import WireFoundation
import WireLocators

struct CompletionView: View {

    enum Action: Sendable {
        case goBack
        case goToTeamManagement
    }

    let actionCallback: (Action) -> Void
    let profileName: String
    let teamName: String

    init(profileName: String, teamName: String, actionCallback: @escaping (Action) -> Void) {
        self.actionCallback = actionCallback
        self.profileName = profileName
        self.teamName = teamName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(String.formated(key: "individualToTeam.completion.body", bundle: .module, teamName))
                .font(for: .body1)
            Spacer()

            Button(
                action: { actionCallback(.goBack) },
                label: { Text(String.localized(key: "individualToTeam.completion.button.backToApp", bundle: .module)) }
            )
            .accessibilityIdentifier(Locators.TeamSetupStepsPage.backToWireButton.rawValue)
            .wireButtonStyle(.secondary)

            Button(
                action: { actionCallback(.goToTeamManagement) },
                label: { Text(String.localized(
                    key: "individualToTeam.completion.button.teamManagement",
                    bundle: .module
                )) }
            )
            .wireButtonStyle(.primary)
        }
    }
}

#Preview {
    completionPreview()
}
