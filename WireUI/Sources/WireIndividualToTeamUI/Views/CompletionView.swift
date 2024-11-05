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

struct CompletionView: View {

    enum Action {
        case goBack
        case goToTeamManagement
    }

    let profileName: String
    let teamName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("You’re now the owner of the team (\(teamName)).")
            Text("Go to Team Management to:\n• Invite your first team members, and start working together\n• Customize your team settings")
            Spacer()

            BackButton(
                action: { },
                title: "Back To Wire"
            )
            CallToActionButton(
                title: "Go To Team Management",
                action: { }
            )
        }
    }
}
