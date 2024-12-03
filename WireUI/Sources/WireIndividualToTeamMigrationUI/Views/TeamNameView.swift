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
import WireFoundation

struct TeamNameView: View {

    enum Action: Sendable {
        case `continue`(teamName: String)
    }

    let actionCallback: (Action) -> Void
    @State private var teamName: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text(String.localized(key: "individualToTeam.teamName.body", bundle: .module))
                .wireTextStyle(.body1)
            Spacer()
                .frame(height: 24)
            Text(String.localized(key: "individualToTeam.teamName.field.title", bundle: .module))
                .wireTextStyle(.h4)
            TextField(String.localized(key: "individualToTeam.teamName.field.placeholder", bundle: .module), text: $teamName)
                .textFieldStyle(.roundedBorder)
                .wireTextStyle(.body1)
            Spacer()

            Button(
                action: { actionCallback(.continue(teamName: teamName)) },
                label: { Text(String.localized(key: "individualToTeam.button.continue", bundle: .module)) }
            )
            .wireButtonStyle(.primary)
            .disabled(teamName.isEmpty)
        }
    }
}
