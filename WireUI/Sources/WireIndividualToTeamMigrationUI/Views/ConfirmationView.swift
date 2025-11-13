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
import WireDesign
import WireFoundation
import WireLocators
import WireReusableUIComponents

struct ConfirmationView: View {

    enum Action: Sendable {
        case `continue`
    }

    let termsOfUseURL: String
    let privacyPolicyURL: String
    let actionCallback: (Action) -> Void
    @State private var migrationConfirmed: Bool = false
    @State private var termsAccepted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 56) {
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: 8) {
                    Text(verbatim: "•")
                    Text(String.localized(key: "individualToTeam.confirmation.body.createTeam", bundle: .module))
                }
                HStack(alignment: .top, spacing: 8) {
                    Text(verbatim: "•")
                    Text(String.localized(key: "individualToTeam.confirmation.body.teamOwner", bundle: .module))
                }
                HStack(alignment: .top, spacing: 8) {
                    Text(verbatim: "•")
                    Text(String.localized(key: "individualToTeam.confirmation.body.permanent", bundle: .module))
                }
            }
            .wireTextStyle(.body1)
            VStack(alignment: .leading, spacing: 16) {
                Checkbox(
                    isChecked: $migrationConfirmed,
                    title: .localized(key: "individualToTeam.confirmation.permanentMigrationCheckbox", bundle: .module)
                )
                Checkbox(
                    isChecked: $termsAccepted,
                    title: .formattedMarkdown(
                        key: "individualToTeam.confirmation.termsCheckbox",
                        bundle: .module,
                        termsOfUseURL,
                        privacyPolicyURL
                    )
                )
            }
            Spacer()
            VStack(alignment: .leading) {
                Button(
                    action: { actionCallback(.continue) },
                    label: { Text(String.localized(key: "individualToTeam.button.continue", bundle: .module)) }
                )
                .accessibilityIdentifier(Locators.TeamSetupStepsPage.continueButton.rawValue)
                .wireButtonStyle(.primary)
                .disabled(!(migrationConfirmed && termsAccepted))
            }
        }
    }
}

#Preview {
    confirmationPreview()
}
