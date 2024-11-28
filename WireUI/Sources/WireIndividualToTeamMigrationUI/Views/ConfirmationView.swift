//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

struct ConfirmationView: View {

    enum Action: Sendable {
        case `continue`
    }

    let actionCallback: (Action) -> Void
    @State var migrationConfirmed: Bool = false
    @State var termsAccepted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 56) {
            Text(String.localized(key: "individualToTeam.confirmation.body", bundle: .module))
                .wireTextStyle(.body1)
            VStack(alignment: .leading, spacing: 16) {
                Checkbox(
                    isChecked: $migrationConfirmed,
                    title: .localized(key: "individualToTeam.confirmation.permanentMigrationCheckbox", bundle: .module)
                )
                Checkbox(
                    isChecked: $termsAccepted,
                    title: .localizedMarkdown(key: "individualToTeam.confirmation.termsCheckbox", bundle: .module)
                )
            }
            Spacer()
            VStack(alignment: .leading) {
                Button(
                    action: { actionCallback(.continue) },
                    label: { Text(String.localized(key: "individualToTeam.button.continue", bundle: .module)) }
                )
                .wireButtonStyle(.primary)
                .disabled(!(migrationConfirmed && termsAccepted))
            }
        }
    }
}
