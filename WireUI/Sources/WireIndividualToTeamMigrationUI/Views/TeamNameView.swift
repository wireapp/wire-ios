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
import WireReusableUIComponents

struct TeamNameView: View {

    enum Action: Sendable {
        case `continue`(teamName: String)
    }

    let actionCallback: (Action) -> Void
    @State private var teamName: String = ""

    var validTeamName: String {
        teamName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(String.localized(key: "individualToTeam.teamName.body", bundle: .module))
                .font(for: .body1)
            Spacer()
                .frame(height: 24)

            LabeledTextField(
                isMandatory: true,
                placeholder: .localized(key: "individualToTeam.teamName.field.placeholder", bundle: .module),
                title: .localized(key: "individualToTeam.teamName.field.title", bundle: .module),
                string: $teamName
            )
            .accessibilityIdentifier(Locators.TeamSetupStepsPage.teamNameTextField.rawValue)

            Spacer()

            Button(
                action: { actionCallback(.continue(teamName: validTeamName)) },
                label: { Text(String.localized(key: "individualToTeam.button.continue", bundle: .module)) }
            )
            .accessibilityIdentifier(Locators.TeamSetupStepsPage.continueButton.rawValue)
            .wireButtonStyle(.primary)
            .disabled(validTeamName.isEmpty)
        }
    }
}

#Preview {
    teamNamePreview()
}
