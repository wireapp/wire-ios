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

    enum Action {
        case goBack
        case `continue`
    }

    @State var password: String = ""
    @State var migrationConfirmed: Bool = false
    @State var termsAccepted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(String.localized(key: "individualToTeam.confirmation.body", bundle: .module))
                .wireTextStyle(.body1)
            VStack(alignment: .leading) {
                Text(String.localized(key: "individualToTeam.confirmation.passwordField.title", bundle: .module))
                    .wireTextStyle(.h4)
                TextField("", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .wireTextStyle(.body1)
            }
            HStack {
                Spacer()
                Button(
                    action: { },
                    label: {
                        Text(String.localized(key: "individualToTeam.confirmation.passwordField.forgotPassword", bundle: .module))
                            .wireTextStyle(.subline1)
                            .foregroundStyle(.gray)
                    }
                )
                .buttonStyle(.plain)
            }
            Spacer()
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
            VStack(alignment: .leading) {
                BackButton(
                    title: String.localized(key: "individualToTeam.button.back", bundle: .module),
                    action: { }
                )
                CallToActionButton(
                    title: String.localized(key: "individualToTeam.button.continue", bundle: .module),
                    action: { }
                )
            }
        }
    }
}
